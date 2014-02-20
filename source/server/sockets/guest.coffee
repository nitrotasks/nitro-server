Socket     = require('../sockets/base')
UserSocket = require('../sockets/user')
core       = require('../../core/api')
token      = require('../controllers/token')
log        = require('log_')('Socket -> guest', 'green')


# How long a connection has to authenticate itself before being kicked
TIMEOUT_AUTH = 3000


class GuestSocket extends Socket

  events:
    user: ['auth']


  ###
   * GuestSocket
   *
   * This will handle a newly created socket and allow them to authenticate
   * themselves. There is a limited time to authenticate before the socket
   * will be automatically closed. This is done so that the server doesn't
   * have to handle any more sockets than it needs to.
   *
   * - socket (Jandal)
  ###

  constructor: (_socket) ->
    super
    log 'A new guest has connected'
    @authenticated = false
    @authTimeout = setTimeout @timeout, TIMEOUT_AUTH
    core.analytics('socket.connect')


  ###
   * User Authentication
   *
   * The callback function will only be called if authentication is successful,
   * otherwise the socket will be instantly closed and an error message will be
   * sent back with it.
   *
   * - userId (int) : id of the user
   * - token (string) : login token
   * - fn (function) : callback
  ###

  user_auth: (socketToken, fn) ->
    clearTimeout(@authTimeout)
    token.verifySocketToken(socketToken)
    .then (user) =>
      @login(user.id, fn)
    .catch (err) =>
      fn('err_bad_token')
      @kick()

  ###
   * (Private) User Login
   *
   * This handles logging in a user after they have been authenticated.
   * It releases control of the Jandal instance and then creates a new
   * UserSocket. If an error occurs, the socket will be closed.
   *
   * - fn (callback)
  ###

  login: (userId, fn) ->
    @unbindEvents()
    core.getUser(userId)
    .then (user) =>
      new UserSocket(@_socket, user)
      user.info()
    .then (info) ->
      fn(null, info)
    .catch (err) =>
      log.warn(err)
      fn('err_bad_token')
      @kick()

  ###
   * (Private) Kick
   *
   * This will close a socket because authentication has failed.
   *
   * [message] (string) : Optional error message
  ###

  kick: (message='err_bad_token') ->
    @close(3002, message)


  ###
   * (Private) Timeout
   *
   * This will close a socket because no attempt was made to authenticate
   * within the time limit.
  ###

  timeout: =>
    @close(1002, 'err_auth_timeout')


module.exports = GuestSocket
