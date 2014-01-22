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
   * - classname (string)
   * - id (string)
   * - model (object)
   * - [timestamp] (number)
  ###

  model_create: (classname, model, timestamp) =>
    id = model.id ?= @createId classname
    @user.setModel classname, id, model
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

    # Add the task to the list
    list = @user.findModel(LIST, model.listId)

    id = @model_create(TASK, model, timestamp)

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
    else
      delete model.id

    # Make sure tasks is empty
    model.tasks = []

    id = @model_create(LIST, model, timestamp)

    return id


  ####################################
  #         __   __       ___  ___   #
  #   |  | |__) |  \  /\   |  |__    #
  #   \__/ |    |__/ /~~\  |  |___   #
  #                                  #
  ####################################


  ###
   * (private) Update Model
   *
  ###

  model_update_setup: (classname, changes, timestamps) =>

    id = changes.id
    delete changes.id

    # Check model exists on server
    unless @user.checkModel(classname, id)
      log "[#{ classname }] [update] could not find #{ id }"
      return false

    return true

  model_update_timestamps: (classname, id, changes, timestamps) ->

    # Set timestamp
    if timestamps
      for attr, time of timestamps
        old = @time.get classname, id, attr
        if old > time
          delete timestamps[attr]
          delete changes[attr]
      if Object.keys(changes).length is 0
        warn "[#{ classname }] [update] all properties are old"
        return null
    else
      timestamps = {}
      now = Date.now()
      for key of changes
        timestamps[key] = now

    return timestamps

  # Save to server
  model_update_save: (classname, id, changes, timestamps) ->
    @time.set(classname, id, timestamps)
    @user.updateModel(classname, id, changes)
    changes.id = id
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
      warn '[task] [update] could not find', id
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
      warn '[task] [update] timestamps is null'
      return null

    return @model_update_save(TASK, id, changes, timestamps)


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
      warn '[list] [update] could not find', id
      return null

    # Set timestamps
    timestamps = @model_update_timestamps(LIST, id, changes, timestamps)
    unless timestamps
      warn '[list] [update] timestamps is null'
      return null

    # Handle tasks
    if changes.tasks
      warn '[list] [update] TODO: Handle list.tasks'
      delete changes.tasks
      delete timestamps.tasks

    return @model_update_save(LIST, id, changes, timestamps)

  pref_update: (changes, timestamps) =>

    # Pref id is always s0
    id = PREF_ID

    # Set timestamp
    if timestamps
      for attr, time of timestamps
        old = @time.get PREF, id, attr
        if old > time
          delete timestamps[attr]
          delete changes[attr]
      if Object.keys(changes).length is 0
        warn '[pref] [update] old event', id
        return null
    else
      timestamps = {}
      now = Date.now()
      for key of changes
        timestamps[key] = now

    @time.set PREF, id, timestamps

    # Save to server
    model = @user.updateModel PREF, id, changes
    log '[pref] updated', changes

    return changes



  ########################################
  #    __   ___  __  ___  __   __        #
  #   |  \ |__  /__`  |  |__) /  \ \ /   #
  #   |__/ |___ .__/  |  |  \ \__/  |    #
  #                                      #
  ########################################

  task_destroy: (id, timestamp) =>

    unless @user.checkModel(TASK, id)
     log '[task] [destroy] could not find:', id
     return null

    model = @user.findModel TASK, id

    # Check that the model hasn't been updated after this event
    timestamp ?= Date.now()
    unless @time.check TASK, id, timestamp
      return null

    # Remove from list
    list = @user.findModel(LIST, model.listId)
    if list.tasks?
      @taskRemove id, list

    # Replace task with deleted template
    @user.setModel TASK, id,
      id: id
      deleted: true

    # Set timestamp
    @time.set TASK, id, 'deleted', timestamp
    log '[task] [destroy] deleted', id

    return true

  list_destroy: (id, timestamp) =>

    console.log 'attempting to destroy list', id

    unless @user.checkModel(LIST, id)
      log '[list] [destroy] could not find:', id
      return null

    model = @user.findModel(LIST, id)

    # Check that the model hasn't been updated after this event
    timestamp ?= Date.now()
    unless @time.check LIST, id, timestamp
      return null

    # Destroy all tasks within that list
    for taskId, i in model.tasks by -1
      @task_destroy taskId, timestamp

    # Replace task with deleted template
    @user.setModel LIST, id,
      id: id
      deleted: yes

    # Set timestamp
    @time.set LIST, id, 'deleted', timestamp
    log '[list] [destroy] deleted:', id

    return true

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
