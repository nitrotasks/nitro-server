SyncTask  = require('../sync/task')
SyncList  = require('../sync/list')
SyncPref  = require('../sync/pref')
SyncQueue = require('../sync/queue')

class SyncUser

  constructor: (@user, @sender) ->
    @task  = new SyncTask(@user, @sender)
    @list  = new SyncList(@user, @sender)
    @pref  = new SyncPref(@user, @sender)
    @queue = new SyncQueue(this)

module.exports = SyncUser
