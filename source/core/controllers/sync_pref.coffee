Sync = require('../controllers/sync_base')

class SyncPref extends Sync

  classname: 'pref'

  create: ->

    # disabled
    throw new Error('Cannot create preference')

  update: (data, timestamps) ->

    super(@user.id, data, timestamps)
  
  destroy: ->

    # disabled
    throw new Error('Cannot destroy preference')
    
module.exports = SyncPref
