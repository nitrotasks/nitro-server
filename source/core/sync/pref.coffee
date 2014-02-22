Sync = require('../sync/base')

class SyncPref extends Sync

  classname: 'pref'

  create: ->

    # disabled
    throw new Error('Cannot create preference')

  update: (_null, data, timestamps) ->

    super(@user.id, data, timestamps)

  destroy: ->

    # disabled
    throw new Error('Cannot destroy preference')

module.exports = SyncPref
