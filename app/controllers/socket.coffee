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
    for name, methods of @events
      ns = @socket.namespace name
      for event of method
        ns.on event, @[name + '_' + event]

  # Release control over the raw socket
  release: ->

  # Disconnect the socket from the server
  disconnect: ->
    @_socket.end()


class GuestSocket extends Socket

  # Websocket events
  events:
    user: ['auth']

  constructor: (socket) ->
    super
    @authenticated = false

  user_auth: (@userId, token) =>
    User.checkLoginToken(@userId, token)
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
    new UserSocket(socket, @userId)


class UserSocket extends Socket

  # Websocket events
  events:
    user: ['disconnect', 'info']
    data: ['sync', 'fetch', 'create', 'update', 'destroy']
    email: ['list']

  constructor: (socket, userId) ->
    super
    @authenticated = true
    @socket.join(userId)
    @sync = new Sync(userId)
    @user = Storage.get(userId)

  user_disconnect: =>
    console.log @socket.room(userId).length()

  user_info: (fn) =>
    fn
      name: @user.name
      email: @user.email
      pro: @user.pro

  data_sync: =>

  data_fetch: =>

  data_create: =>

  data_update: =>

  data_destroy: =>

  email_list: =>


module.exports = init
