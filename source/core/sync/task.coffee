Promise = require('bluebird')
Sync    = require('../sync/base')
{Task}  = require('../models/task')

class SyncTask extends Sync

  classname: 'task'

  ###
   * Create Task
   *
   * - model (object)
   * - timestamp (number)
   * > id (number)
  ###

  create: (data, timestamp) ->

    @user.list.owns(data.listId)
    .then =>
      super(data, timestamp)
    .then (id) ->
      Task::addToList.call({ id }, data.listId).return(id)

  _update_validation: (model, data, timestamps) ->

    # Move a task to another list
    return Promise.resolve() unless data.listId

    @user.list.owns(data.listId)
    .then ->
      model.read('listId')
    .then (current) ->
      throw null if current.listId is data.listId
      model.moveToList(data.listId)
    .catch (ignore) ->
      delete data.listId
      delete timestamps?.listId

module.exports = SyncTask
