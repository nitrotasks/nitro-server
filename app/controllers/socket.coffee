sockjs = require 'sockjs'
Jandal = require 'jandal'

init = ->
  websockets = sockjs.createServer()
  websockets.installHandlers server, prefix: '/socket'
  websockets.on 'connection', (socket) ->
    new GuestSocket(socket)

class Socket

  constructor: (@_socket) ->
    @socket = new Jandal(@_socket)
    @bindEvents()

  bindEvents: ->
    return unless @events
    for event, method of @events
      @socket.on event, @[method]

  # Release control over the raw socket
  release: ->

  # Disconnect the socket from the server
  disconnect: ->


class GuestSocket extends Socket

  # Websocket events
  events:
    'auth': 'auth'

  constructor: ->
    super
    @authenticated = false

  auth: (userId, token) =>
    User.checkLoginToken(userId, token)
      .then (exists) =>
        if exists
          @login()
        else
          @disconnect()
      .fail ->
        @disconnect()

  login: ->
    socket = @_socket
    @release()
    new UserSocket(socket)


class UserSocket extends Socket

  # Websocket events
  events:
    'disconnect' : 'logout'
    'fetch'      : 'fetch'
    'sync'       : 'sync'
    'create'     : 'create'
    'update'     : 'update'
    'destroy'    : 'destroy'
    'info'       : 'info'
    'emailList'  : 'emailList'

module.exports = init
