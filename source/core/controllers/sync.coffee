SyncTask  = require('../sync/task')
SyncList  = require('../sync/list')
SyncPref  = require('../sync/pref')
SyncQueue = require('../sync/queue')

class SyncUser

  constructor: (@user) ->
    @task  = new SyncTask(@user)
    @list  = new SyncList(@user)
    @pref  = new SyncPref(@user)

    # TODO: refactor this
    @queue = (queue, clientTime) ->
      SyncQueue(this, queue, clientTime)

module.exports = SyncUser
