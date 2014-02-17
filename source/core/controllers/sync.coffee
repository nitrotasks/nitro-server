Promise = require('bluebird')
log     = require('log_')('Sync', 'cyan')
time    = require('../models/time')
{Task}  = require('../models/task')
{List}  = require('../models/list')
{Pref}  = require('../models/pref')
mergeQueue = require('../controllers/queue')

# CONSTANTS

LIST = 'list'
PREF = 'pref'
TASK = 'task'

ERR_INVALID_MODEL = 'err_invalid_model'
ERR_OLD_EVENT = 'err_old_event'


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
    .then => @user.tasks.create(data)
    .then (id) ->
      log '[task] [create]', id, data
      Promise.all([
        time.task.create(id, timestamp)
        Task::addToList.call({ id }, data.listId)
      ]).return(id)


  ###
   * Create List
   *
   * - model (object)
   * - timestamp (number)
   * > id (number)
  ###

  list_create: (data, timestamp) =>

    @user.lists.create(data).then (id) ->
      log '[list] [create]', id, data
      time.list.create(id, timestamp).return(id)


  ####################################
  #         __   __       ___  ___   #
  #   |  | |__) |  \  /\   |  |__    #
  #   \__/ |    |__/ /~~\  |  |___   #
  #                                  #
  ####################################


  ###
   * Update Task
   *
   * - changes (object)
   * - timestamps
   * > changes
  ###

  task_update: (id, data, times) =>

    task = null

    if Object.keys(data).length is 0
      return Promise.reject new Error(ERR_INVALID_MODEL)

    # Make sure that the task exists and that the user owns it
    @user.tasks.get(id)
    .then (_task) ->
      task = _task

      time.task.checkMultiple(id, data, times)

    .then (_times) =>
      times = _times

      # Move a task to another list
      return unless data.listId

      @user.lists.owns(data.listId)
      .then ->
        task.read('listId')
      .then (current) ->
        throw null if current.listId is data.listId
        task.removeFromList(current.listId)
      .then ->
        task.addToList(data.listId)
      .catch (ignore) ->
        delete data.listId
        delete times?.listId

    .then -> # Set times
      time.task.update(id, times)
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
    .then (_list) ->

      list = _list

      # TODO: Handle tasks
      if data.tasks
        log.warn '[list] [update] TODO: Handle list.tasks'
        delete data.tasks
        delete timestamps.tasks

      # Update timestamps
      time.list.updateMultiple(id, data, timestamps)

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

    time.pref.updateMultiple(@user.id, data, timestamps)
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
    .then (_task) ->
      task = _task
      time.task.checkSingle(id, timestamp)
    .then ->
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
    .then (_list) ->
      list = _list
      time.list.checkSingle(id, timestamp)
    .then ->
      log '[list] [destroy]', id
      list.destroy()

  queue: (queue, clientTime) ->

    mergeQueue(this, queue, clientTime)

module.exports = Sync
