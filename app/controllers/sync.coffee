###
           ___  __   __      __            __
    |\ | |  |  |__) /  \    /__` \ / |\ | /  `
    | \| |  |  |  \ \__/    .__/  |  | \| \__,

    ------------------------------------------

    This is the sync code. It's a wee bit crazy.

###


Q       = require 'kew'
Log     = require '../utils/log'
Time    = require '../utils/time'

log      = Log 'Sync', 'cyan'
logEvent = Log 'Sync Event', 'yellow'
warn     = Log 'Sync', 'red'

# CONSTANTS

LIST = 'list'
PREF = 'pref'
TASK = 'task'
INBOX = 'inbox'

SERVER_PREFIX = 's'
PREF_ID = SERVER_PREFIX + '0'


# Does all the useful stuff
class Sync

  constructor: (@user) ->
    @time = new Time(@user)


  ###
   * Create a new ID for a model
   *
   * - classname (string)
   * > int
  ###

  createId: (classname) ->
    id = @user.incrIndex classname
    return SERVER_PREFIX + (id - 1)


  #####################################
  #    __   __   ___      ___  ___    #
  #   /  ` |__) |__   /\   |  |__     #
  #   \__, |  \ |___ /~~\  |  |___    #
  #                                   #
  #####################################

  ###
   * (private) Create Model
   *
   * Assigns an id, saves it to the database and
   * also inits the timestamps.
   *
   * - classname (string)
   * - model (object)
   * - [timestamp] (number)
   * > id
  ###

  model_create: (classname, model, timestamp) =>

    # Assign a new ID if it hasn't already got one
    id = model.id ?= @createId classname

    # Save to database
    @user.setModel classname, id, model

    # Handle timestamp
    timestamp ?= Date.now()
    @time.set classname, id, '*', timestamp

    log "[#{ classname }] [create] created", id
    return id


  ###
   * Create Task
   *
   * - model (object)
   * - timestamp (number)
   * > id (number)
  ###

  task_create: (model, timestamp) =>

    # Throw away client id
    delete model.id

    # Check that the list exists
    unless @user.checkModel(LIST, model.listId)
      warn '[task] [create] can not find listId', model.listId
      return null

    id = @model_create(TASK, model, timestamp)

    # Add the task to the list
    list = @user.findModel(LIST, model.listId)
    @taskAdd id, list

    return id


  ###
   * Create List
   *
   * - model (object)
   * - timestamp (number)
   * > id (number)
  ###

  list_create: (model, timestamp) =>

    # Handle inbox list
    if model.id is INBOX
      if @user.hasModel(LIST, INBOX)
        warn '[list] [create] can not recreate inbox'
        return null

    # Throw away the client id
    else
      delete model.id

    # Make sure tasks is empty
    model.tasks = []

    return @model_create(LIST, model, timestamp)


  ####################################
  #         __   __       ___  ___   #
  #   |  | |__) |  \  /\   |  |__    #
  #   \__/ |    |__/ /~~\  |  |___   #
  #                                  #
  ####################################


  ###
   * (private) Update Model
   *
   * Setup update event
   *
   * - classname (string)
   * - changes (object)
   * - timestamps (object)
   * > boolean
  ###

  model_update_setup: (classname, changes, timestamps) =>

    # Delete id because we don't want to overwrite it
    id = changes.id
    delete changes.id

    # Check model exists on server
    unless @user.checkModel(classname, id)
      warn "[#{ classname }] [update] could not find #{ id }"
      return false

    return true


  ###
   * (private) Model Update Timestamps
   *
   * Handle timestamps for an update event
   *
   * - classname (string)
   * - id (string)
   * - changes (object)
   * - timestamps (object)
   * > timestamps
  ###

  model_update_timestamps: (classname, id, changes, timestamps) ->

    if timestamps
      for attr, time of timestamps

        # Check timestamp is newer than the last timestamp
        old = @time.get classname, id, attr
        if old > time
          delete timestamps[attr]
          delete changes[attr]

      # If we have no events left, exit
      if Object.keys(changes).length is 0
        warn "[#{ classname }] [update] all properties are old"
        return null

    else
      timestamps = {}
      now = Date.now()
      for key of changes
        timestamps[key] = now

    return timestamps


  ###
   * (private) Model Update Save
   *
   * Save model changes and timestamps
   *
   * - classname (string)
   * - id (string)
   * - changes (object)
   * - timestamps (object)
   * > changes
  ###

  model_update_save: (classname, id, changes, timestamps) ->
    log "[#{ classname }] [update] saved #{ id }"
    @time.set(classname, id, timestamps)
    @user.updateModel(classname, id, changes)
    return changes


  ###
   * Update Task
   *
   * - changes (object)
   * - timestamps
   * > changes
  ###

  task_update: (changes, timestamps) =>

    id = changes.id

    unless @model_update_setup(TASK, changes, timestamps)
      return null

    # Check listId
    if changes.listId?
      unless @user.checkModel(LIST, changes.listId)
        warn '[task] [update] could not find listId', changes.listId
        return null
      oldTask = @user.findModel(TASK, id)
      if oldTask.listId isnt changes.listId
        @taskMove(id, oldTask.listId, changes.listId)

    # Set timestamps
    timestamps = @model_update_timestamps(TASK, id, changes, timestamps)
    unless timestamps
      return null

    @model_update_save(TASK, id, changes, timestamps)

    changes.id = id
    return changes


  ###
   * Update List
   *
   * - changes (object)
   * - timestamps (object)
   * > changes
  ###

  list_update: (changes, timestamps) =>

    id = changes.id

    unless @model_update_setup(LIST, changes, timestamps)
      return null

    # Set timestamps
    timestamps = @model_update_timestamps(LIST, id, changes, timestamps)
    unless timestamps
      return null

    # Handle tasks
    if changes.tasks
      warn '[list] [update] TODO: Handle list.tasks'
      delete changes.tasks
      delete timestamps.tasks

    @model_update_save(LIST, id, changes, timestamps)

    changes.id = id
    return changes


  ###
   * Update Pref
   *
   * - changes (object)
   * - timestamps (timestamps)
   * > changes
  ###

  pref_update: (changes, timestamps) =>

    # Pref id is always s0
    id = PREF_ID

    timestamps = @model_update_timestamps(PREF, id, changes, timestamps)
    unless timestamps
      return null

    return @model_update_save(PREF, id, changes, timestamps)



  ########################################
  #    __   ___  __  ___  __   __        #
  #   |  \ |__  /__`  |  |__) /  \ \ /   #
  #   |__/ |___ .__/  |  |  \ \__/  |    #
  #                                      #
  ########################################


  ###
   * (private) Model Destroy Setup
   *
   * Check that model exists, and set the timestamp for it
   *
   * - classname (string)
   * - id (string)
   * - timestamp (number)
   * > model
  ###

  model_destroy_setup: (classname, id) =>

    unless @user.checkModel(classname, id)
      warn "[#{ classname }] [destroy] could not find #{ id }"
      return null

    # Get existing model
    model = @user.findModel(classname, id)

    return model


  ###
   * Model Destroy Timestamp
   *
   * Check that the model hasn't been updated after this event
   *
   * - classname (string)
   * - id (string)
   * - timestamp (number)
   * > timestamp
  ###

  model_destroy_timestamp: (classname, id, timestamp) =>

    timestamp ?= Date.now()
    unless @time.check classname, id, timestamp
      warn "[#{ classname }] [destroy] updated after delete time: #{ id }"
      return null

    return timestamp


  ###
   * (private) Model Destroy Save
   *
   * Overwrite model with deleted object template and
   * save deleted timestamp.
   *
   * - classname (string)
   * - id (string)
   * - timestamp (number)
   * > true
  ###

  model_destroy_save: (classname, id, timestamp) =>

    @user.setModel classname, id,
      id: id
      deleted: yes

    @time.set(classname, id, 'deleted', timestamp)
    log "[#{ classname }] [destroy] deleted #{ id }"

    return true


  ###
   * Destroy Task
   *
   * - id (string)
   * - timestamp (number)
  ###

  task_destroy: (id, timestamp) =>

    model = @model_destroy_setup(TASK, id)
    return null unless model

    timestamp = @model_destroy_timestamp(TASK, id, timestamp)
    return null unless timestamp

    # Remove from list
    list = @user.findModel(LIST, model.listId)
    if list.tasks?
      @taskRemove id, list

    return @model_destroy_save(TASK, id, timestamp)


  ###
   * Destroy List
   *
   * - id (string)
   * - timestamp (number)
  ###

  list_destroy: (id, timestamp) =>

    model = @model_destroy_setup(LIST, id)
    return null unless model

    timestamp = @model_destroy_timestamp(LIST, id, timestamp)
    return null unless timestamp

    # Destroy all tasks within that list
    for taskId, i in model.tasks by -1
      @task_destroy taskId, timestamp

    return @model_destroy_save(LIST, id, timestamp)


# -----------------------------------------------------------------------------
# Useful Task Management Methods
# -----------------------------------------------------------------------------


  # Add a task to a list
  taskAdd: (taskId, list) ->
    tasks = list.tasks
    return false unless tasks
    if tasks.indexOf(taskId) < 0
      tasks.push taskId
      @user.save LIST

  # Remove a task from a list
  taskRemove: (taskId, list) ->
    tasks = list.tasks
    return false unless tasks
    index = tasks.indexOf taskId
    if index >= 0
      tasks.splice index, 1
      @user.save LIST

  # Move a task from list to another
  taskMove: (taskId, oldListId, newListId) ->
    list = @user.findModel(LIST, newListId)
    @taskAdd taskId, list
    list = @user.findModel(LIST, oldListId)
    @taskRemove taskId, list

  # Replace a task ID
  taskUpdateId: (oldId, newId, listId) ->
    tasks = @user.findModel(LIST, listId).tasks
    index = tasks.indexOf oldId
    if index >= 0
      tasks.spice index, 1, newId
      @user.save LIST

module.exports = Sync
