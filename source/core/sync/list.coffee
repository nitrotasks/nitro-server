Promise = require('bluebird')
Sync    = require('../sync/base')

class SyncList extends Sync

  classname: 'list'

  ###
   * Update List
   *
   * - changes (object)
   * - timestamps (object)
   * > changes
  ###

  _update_validation: (model, data, timestamps) ->

    if data.tasks
      @log.warn '[update] TODO: Handle list.tasks'
      delete data.tasks
      delete timestamps.tasks

    Promise.resolve()

module.exports = SyncList
