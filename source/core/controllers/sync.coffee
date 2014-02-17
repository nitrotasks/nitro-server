SyncTask  = require('../controllers/sync_task')
SyncList  = require('../controllers/sync_list')
SyncPref  = require('../controllers/sync_pref')
SyncQueue = require('../controllers/sync_queue')

class SyncUser

  constructor: (@user) ->
    @task  = new SyncTask(@user)
    @list  = new SyncList(@user)
    @pref  = new SyncPref(@user)

    # TODO: refactor this
    @queue = (queue, clientTime) ->
      SyncQueue(this, queue, clientTime)

module.exports = SyncUser
