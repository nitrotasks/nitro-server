sockjs = require 'sockjs'
Jandal = require 'jandal'
Sync = require '../controllers/sync'
Storage = require '../controllers/storage'
Log = require '../utils/log'

log = Log 'Socket', 'yellow'
Jandal.handle 'node'


# -----------------------------------------------------------------------------
# Init
# -----------------------------------------------------------------------------

init = (server, sjs=sockjs) ->
  websockets = sjs.createServer()
  websockets.installHandlers server, prefix: '/socket'
  websockets.on 'connection', (socket) ->
    new GuestSocket(socket)


# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

# How long a connection has to authenticate itself before being kicked
TIMEOUT_AUTH = 3000

# What classnames can be edited
CLASSES = ['list', 'task', 'pref']


# -----------------------------------------------------------------------------
# Socket
# -----------------------------------------------------------------------------

class Socket

  constructor: (@_socket) ->
    @socket = new Jandal(@_socket)
    @bindEvents()

  bindEvents: (action='on') =>
    return unless @events
    for name, methods of @events
      ns = @socket.namespace name
      for event in methods
        ns[action] event, @[name + '_' + event]

  # Release control over the raw socket
  release: =>
    @bindEvents('removeListener')

  # Disconnect the socket from the server
  end: =>
    @_socket.end()

  # Status codes: http://tools.ietf.org/html/rfc6455#section-7.4.1
  close: (status, message) =>
    @_socket.close(status, message)


# -----------------------------------------------------------------------------
# GuestSocket
# -----------------------------------------------------------------------------

class GuestSocket extends Socket

  # Websocket events
  events:
    user: ['auth']

  constructor: (socket) ->
    super
    log 'A new guest has connected'
    @authenticated = false
    setTimeout @timeout, TIMEOUT_AUTH

  user_auth: (@userId, token, fn) =>
    Storage.checkLoginToken(@userId, token)
      .then (exists) =>
        if exists
          @login(fn)
        else
          fn(false)
          @end()
      .fail (err) ->
        @end()

  login: (callback) =>
    socket = @_socket
    @release()
    Storage.get(@userId)
      .then (user) =>
        new UserSocket(socket, user)
        callback(true)
      .fail (err) =>
        @kick()

  kick: =>
    @close 3002, 'err_bad_token'

  timeout: =>
    @close 1002, 'err_auth_timeout'


# -----------------------------------------------------------------------------
# UserSocket
# -----------------------------------------------------------------------------

class UserSocket extends Socket

  # Websocket events
  events:
    user: ['info']
    model: ['sync', 'fetch', 'create', 'update', 'destroy']
    email: ['list']

  constructor: (socket, @user) ->
    super
    log 'A user has been authenticated'
    @authenticated = true
    @_socket.on 'close', @logout
    @socket.join(@user.id)
    @sync = new Sync(@user)

  broadcast: (event, classname, arg1, arg2, arg3) =>
    event = classname + '.' + event
    @socket.broadcast.to(@user.id).emit(event, arg1, arg2, arg3)

  user_info: (fn) =>
    fn
      name: @user.name
      email: @user.email
      pro: @user.pro

  model_sync: (queue, fn) =>
    @sync.sync(queue, fn)

  model_fetch: (classname, fn) =>

    if classname not in CLASSES or
    typeof fn isnt 'function'
      return false

    fn @user.exportModel(classname)

  model_create: (classname, model, fn) =>

    if classname not in CLASSES or
    typeof fn isnt 'function' or
    typeof model isnt 'object'
      return

    id = @sync.create(classname, model)
    @broadcast 'create', classname, model
    fn(id)

  ###
   * - classname (string)
   * - model (object)
   * - [fn] (function)
  ###
  
  model_update: (classname, model, fn) =>

    if classname not in CLASSES or
    typeof model isnt 'object'
      return

    model = @sync.update classname, model
    @broadcast 'update', classname, model

    if typeof fn is 'function' then fn()

  model_destroy: (classname, id) =>

    @sync.destroy classname, id
    @broadcast 'destroy', classname, id

  email_list: =>

  logout: =>
    # If the user is only logged in from one client then remove them from memory
    if Jandal.all.in(@user.id).length() is 0
      Storage.release @user.id


module.exports =
  init: init
