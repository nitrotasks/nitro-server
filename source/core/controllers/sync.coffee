###
           ___  __   __      __            __
    |\ | |  |  |__) /  \    /__` \ / |\ | /  `
    | \| |  |  |  \ \__/    .__/  |  | \| \__,

    ------------------------------------------

    This is the sync code. It's a wee bit crazy.

###


Promise = require 'bluebird'
Log     = require '../utils/log'
time    = require '../utils/time'

log      = Log 'Sync', 'cyan'
logEvent = Log 'Sync Event', 'yellow'
warn     = Log 'Sync', 'red'

# CONSTANTS

LIST = 'list'
PREF = 'pref'
TASK = 'task'

ERR_INVALID_MODEL = 'err_invalid_model'
ERR_OLD_EVENT = 'err_old_event'


hasSameKeys = (a, b) ->

  aKeys = Object.keys(a)
  bKeys = Object.keys(b)

  if aKeys.length is bKeys.length
    if aKeys.every( (key) -> b.hasOwnProperty(key) )
      return aKeys

  return false



# Does all the useful stuff
class Sync

  constructor: (@user) ->


  #####################################
  #    __   __   ___      ___  ___    #
  #   /  ` |__) |__   /\   |  |__     #
  #   \__, |  \ |___ /~~\  |  |___    #
  #                                   #
  #####################################


  ###
   * Create Task
   *
   * - model (object)
   * - timestamp (number)
   * > id (number)
  ###

  task_create: (task, timestamp) =>

    # Check that the list exists
    @user.shouldOwnList(task.listId).then (exists) =>

      unless exists
        warn '[task] [create] can not find listId', task.listId
        throw ERR_INVALID_MODEL

      @user.createTask(task)

    .then (id) =>

      # Set id
      task.id = id

      timestamp ?= time.now()
      time.createTask id, timestamp

    .then (id) =>

      # Add the task to the list
      @user.addTaskToList(task.id, task.listId)

    .then ->

      log '[task] [create]', task

      return task.id


  ###
   * Create List
   *
   * - model (object)
   * - timestamp (number)
   * > id (number)
  ###

  list_create: (list, timestamp) =>

    @user.createList(list).then (id) ->

      # Set id
      list.id = id

      timestamp ?= time.now()
      time.createList list.id, timestamp

    .then  ->

      log '[list] [create]', list

      # Return new id
      return list.id



  ####################################
  #         __   __       ___  ___   #
  #   |  | |__) |  \  /\   |  |__    #
  #   \__/ |    |__/ /~~\  |  |___   #
  #                                  #
  ####################################

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

  model_update_create_timestamps: (changes) ->

    timestamps = {}
    now = time.now()
    for key of changes
      timestamps[key] = now

    Promise.resolve timestamps


  model_update_timestamps: (classname, id, changes, timestamps) ->

    if timestamps

      keys = hasSameKeys(changes, timestamps)

      if keys is false
        return Promise.reject ERR_INVALID_MODEL

      time.checkMultiple(classname, id, timestamps).then (oldKeys) ->

        for key in oldKeys
          delete timestamps[key]
          delete changes[key]

        if oldKeys.length is keys.length
          throw ERR_OLD_EVENT

        return timestamps


    else
      @model_update_create_timestamps(changes)





  ###
   * Update Task
   *
   * - changes (object)
   * - timestamps
   * > changes
  ###

  task_update: (changes, timestamps) =>

    id = changes.id
    delete changes.id

    if Object.keys(changes).length is 0
      return Promise.reject ERR_INVALID_MODEL

    # Make sure that the task exists and that the user owns it
    @user.shouldOwnTask(id).then =>

      # Check timestamps
      @model_update_timestamps(TASK, id, changes, timestamps)

    .then (_timestamps) =>
      timestamps = _timestamps

      # Check list ID
      if not changes.listId
        return Promise.resolve()

      @user.shouldOwnList(changes.listId)
      .then =>
        @user.readTask(id, 'listId')

      .then (old) =>
        if old.listId is changes.listId
          throw ERR_INVALID_MODEL

        @user.removeTaskFromList id, old.listId

      .then =>
        @user.addTaskToList id, changes.listId

      .catch (err) ->
        delete changes.listId
        delete timestamps.listId

    .then =>

      # Set timestamps
      time.update(TASK, id, timestamps)

    .then =>

      # Save changes
      @user.updateTask(id, changes)

    .then ->

      changes.id = id

      log '[task] [update]', changes

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
    delete changes.id

    if Object.keys(changes).length is 0
      return Promise.reject ERR_INVALID_MODEL

    @user.shouldOwnList(id)
      .then =>

        # TODO: Handle tasks
        if changes.tasks
          warn '[list] [update] TODO: Handle list.tasks'
          delete changes.tasks
          delete timestamps.tasks

        # Check timestamps
        @model_update_timestamps(LIST, id, changes, timestamps)

      .then (timestamps) =>

        # Set timestamps
        time.update(LIST, id, timestamps)

      .then =>

        # Save changes
        @user.updateList(id, changes)

      .then ->

        changes.id = id

        log '[list] [update]', changes

        return changes


  ###
   * Update Pref
   *
   * - changes (object)
   * - timestamps (timestamps)
   * > changes
  ###

  pref_update: (changes, timestamps) =>

    if Object.keys(changes).length is 0
      return Promise.reject ERR_INVALID_MODEL

    @model_update_timestamps(PREF, @user.id, changes, timestamps)
    .then (timestamps) =>

      time.update(PREF, @user.id, timestamps)

    .then =>

      @user.updatePref(changes)

    .then ->

      log '[pref] [update]', changes

      return changes



  ########################################
  #    __   ___  __  ___  __   __        #
  #   |  \ |__  /__`  |  |__) /  \ \ /   #
  #   |__/ |___ .__/  |  |  \ \__/  |    #
  #                                      #
  ########################################


  ###
   * Destroy Task
   *
   * - id (string)
   * - timestamp (number)
  ###

  task_destroy: (id, timestamp) =>

    @user.shouldOwnTask(id)
    .then =>

      time.checkSingle(TASK, id, timestamp)

    .then =>

      log '[task] [destroy]', id

      @user.destroyTask id

  ###
   * Destroy List
   *
   * - id (string)
   * - timestamp (number)
  ###

  list_destroy: (id, timestamp) =>

    @user.shouldOwnList(id)
    .then =>

      time.checkSingle(LIST, id, timestamp)

    .then =>

      log '[list] [destroy]', id

      @user.destroyList id


module.exports = Sync
