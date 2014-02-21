SyncTask  = require('../sync/task')
SyncList  = require('../sync/list')
SyncPref  = require('../sync/pref')
SyncQueue = require('../sync/queue')

class SyncUser

  constructor: (@user, @sender) ->
    @task  = new SyncTask(@user, @sender)
    @list  = new SyncList(@user, @sender)
    @pref  = new SyncPref(@user, @sender)

    # TODO: refactor this
    @queue = (queue, clientTime) ->
      SyncQueue(this, queue, clientTime)

module.exports = SyncUser
