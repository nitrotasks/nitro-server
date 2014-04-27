Jandal = require('jandal')
xType  = require('xtype')
require('../controllers/validation')

HANDLER = 'stream'

class Socket

  ###
   * Socket
   *
   * - _socket (Socket) : a WebSocket connection
  ###

  constructor: (@_socket) ->
    @socket = new Jandal(@_socket, HANDLER)
    @bindEvents()


  ###
   * (Private) Bind Events
   *
   * Loop thorough each event in @events and bind them to the socket.
   * @events should be an object in the format { <namespace>: [ <event> ] }
   * The function handler should be named <namespace>_<event>
   *
   * - [action] (string)
  ###

  bindEvents: (action='on') ->
    return unless @events
    for name, methods of @events
      ns = @socket.namespace(name)
      for event in methods
        id = name + '_' + event
        fn = xType.guard(id, @[id], this)
        ns[action](event, fn)


  ###
   * UnbindEvents
   *
   * Release control over the web socket.
   * This just unbinds all the events.
  ###

  unbindEvents: ->
    @bindEvents('removeListener')


  ###
   * End
   *
   * Disconnect the socket from the server using the default status code and
   * error message.
  ###

  end: ->
    @_socket.end()


  ###
   * Close
   *
   * Close the socket connection and also send a status code and error message.
   * Status codes: http://tools.ietf.org/html/rfc6455#section-7.4.1
   *
   * - status (int)
   * - message (string)
  ###

  close: (status, message) ->
    @_socket.close(status, message)


module.exports = Socket
