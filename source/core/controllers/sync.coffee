Promise = require('bluebird')
log     = require('log_')('Sync', 'cyan')
time    = require('../models/time')
{Task}  = require('../models/task')
{List}  = require('../models/list')
{Pref}  = require('../models/pref')

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

  task_create: (data, timestamp) =>

    # Check that the list exists
    @user.lists.owns(data.listId)
    .then =>

      @user.tasks.create(data)

    .then (id) ->

      # Set id
      data.id = id

      timestamp ?= time.now()
      time.createTask(id, timestamp)

    .then (task) ->

      # Add the task to the list
      Task::addToList.call(data, data.listId)

    .then ->

      log '[task] [create]', data
      return data.id


  ###
   * Create List
   *
   * - model (object)
   * - timestamp (number)
   * > id (number)
  ###

  list_create: (data, timestamp) =>

    @user.lists.create(data)
    .then (id) ->

      # Set id
      data.id = id

      timestamp ?= time.now()
      time.createList(id, timestamp)

    .then ->

      log '[list] [create]', data

      # Return new id
      return data.id



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

  task_update: (id, data, timestamps) =>

    task = null

    if Object.keys(data).length is 0
      return Promise.reject new Error(ERR_INVALID_MODEL)

    # Make sure that the task exists and that the user owns it
    @user.tasks.get(id)
    .then (_task) =>
      task = _task

      # Check timestamps
      @model_update_timestamps(TASK, id, data, timestamps)

    .then (_timestamps) =>
      timestamps = _timestamps

      # Move a task to another list
      return unless data.listId
      @user.lists.own(data.listId)
      .then ->
        task.read('listId')
      .then (current) ->
        throw null if current.listId is data.listId
        task.removeFromList(current.listId)
      .then ->
        task.addToList(data.listi)
      .catch (ignore) ->
        delete data.listId
        delete timestamps.listId

    .then => # Set timestamps
      time.update(TASK, id, timestamps)
    .then -> # Save data
      task.update(data)
    .then -> # Return task
      log '[task] [update]', data
      return data


  ###
   * Update List
   *
   * - changes (object)
   * - timestamps (object)
   * > changes
  ###

  list_update: (id, data, timestamps) =>

    list = null

    if Object.keys(data).length is 0
      return Promise.reject ERR_INVALID_MODEL

    @user.lists.get(id)
    .then (_list) =>

      list = _list

      # TODO: Handle tasks
      if data.tasks
        log.warn '[list] [update] TODO: Handle list.tasks'
        delete data.tasks
        delete timestamps.tasks

      # Check timestamps
      @model_update_timestamps(LIST, id, data, timestamps)

    .then (timestamps) =>

      # Set timestamps
      time.update(LIST, id, timestamps)

    .then ->

      # Save data
      list.update(data)

    .then ->

      log '[list] [update]', data

      return data


  ###
   * Update Pref
   *
   * - changes (object)
   * - timestamps (timestamps)
   * > changes
  ###

  pref_update: (data, timestamps) =>

    if Object.keys(data).length is 0
      return Promise.reject ERR_INVALID_MODEL

    @model_update_timestamps(PREF, @user.id, data, timestamps)
    .then (timestamps) =>
      time.update(PREF, @user.id, timestamps)
    .then =>
      @user.pref.update(data)
    .then ->
      log '[pref] [update]', data
      return data



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

    task = null

    @user.tasks.get(id)
    .then (_task) =>

      task = _task
      time.checkSingle(TASK, id, timestamp)

    .then =>

      log '[task] [destroy]', id
      task.destroy()

  ###
   * Destroy List
   *
   * - id (string)
   * - timestamp (number)
  ###

  list_destroy: (id, timestamp) =>

    list = null

    @user.lists.get(id)
    .then (_list) =>

      list = _list
      time.checkSingle(LIST, id, timestamp)

    .then =>

      log '[list] [destroy]', id
      list.destroy()


module.exports = Sync
