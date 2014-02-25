sockjs      = require('sockjs')
GuestSocket = require('../sockets/guest')
Jandal      = require('jandal')
event       = require('../../core/api').event


SOCKET_URL = '/socket'


###
 * Init
 *
 * Start the SockJS server and attach it to the HTTP server
 *
 * - server (Server) - web server to attach to
 * - [sjs] (SockJS) - used for testing so we can inject our own mock server
###

init = (server) ->

  websockets = sockjs.createServer()
  websockets.installHandlers(server, prefix: SOCKET_URL)
  websockets.on 'connection', (socket) ->
    new GuestSocket(socket)

  event.listen (message) ->
    console.log '=== EVENT.LISTEN ===', message
    room = Jandal.in(message.user)
    room.broadcast message.sender, message.event,
      message.args[0],
      message.args[1],
      message.args[2]

module.exports =
  init: init
