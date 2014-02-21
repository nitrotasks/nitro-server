Promise = require('bluebird')
pubsub = require('../controllers/pubsub')

CHANNEL = 'nitro'

emit = (options) ->

  message = [
    options.sender
    options.user
    options.event
    options.args
  ]

  string = JSON.stringify(message)

  pubsub.publish(CHANNEL, string)

listen = (fn) ->
  deferred = Promise.defer()

  queue = pubsub.subscribe(CHANNEL)

  queue.on 'message', (channel, message) ->
    [sender, user, event, args] = JSON.parse(message)
    fn {sender, user, event, args}


  queue.on 'subscribe',(channel, count) ->
    deferred.resolve([channel, count])

  return deferred.promise

module.exports = { emit, listen }
