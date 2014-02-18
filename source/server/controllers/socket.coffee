sockjs      = require('sockjs')
GuestSocket = require('../sockets/guest')


SOCKET_URL = '/socket'


###
 * Init
 *
 * Start the SockJS server and attach it to the HTTP server
 *
 * - server (Server) - web server to attach to
 * - [sjs] (SockJS) - used for testing so we can inject our own mock server
###

init = (server, sjs=sockjs) ->
  websockets = sjs.createServer()
  websockets.installHandlers(server, prefix: SOCKET_URL)
  websockets.on 'connection', (socket) ->
    new GuestSocket(socket)


module.exports =
  init: init
