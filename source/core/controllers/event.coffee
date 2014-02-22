Promise = require('bluebird')
pubsub = require('../controllers/pubsub')
{EventEmitter} = require('events')

CHANNEL = 'nitro'

###
 * Emit
 *
 * This will emit an event to the messaging service.
 * The message is sent as a JSON array, to conserve space.
 *
 * - options (object)
 *   - sender (string) : who is sending the message.
 *   - user (number) : the user id the message relates to
 *   - event (string) : the event name
 *   - args (array) : any arguments to pass with the event
 *
 * Example message:
 *
 *   {
 *     sender: '0000-1111-2222-3333',
 *     user: 342,
 *     event: 'task.create',
 *     args: [{ id: 482, name: 'my task', ... }]
 *   }
 *
 * Sender is used to prevent websocket clients from receiving their own
 * messages.
 *
###

emit = (options) ->

  message = [
    options.sender
    options.user
    options.event
    options.args
  ]

  string = JSON.stringify(message)

  pubsub.publish(CHANNEL, string)


###
 * Listen
 *
 * This will subscribe to the messaging service, and pass message events to the
 * callback function.
 * It only uses one subscription, but can handle multiple callback handles.
 *
 * - fn (function) : callback function. Is passed a message object.
###

queue = null
subscription = Promise.defer()
vent = new EventEmitter()

listen = (fn) ->

  # Pass messages to callback function
  vent.on('message', fn)

  # Only setup the queue once
  if queue
    return subscription.promise

  # Subscribe to the queue
  queue = pubsub.subscribe(CHANNEL)

  queue.on 'message', (channel, message) ->
    [sender, user, event, args] = JSON.parse(message)
    vent.emit('message', {sender, user, event, args})

  queue.on 'subscribe', (channel, count) ->
    subscription.resolve()

  return subscription.promise

module.exports = { emit, listen }
