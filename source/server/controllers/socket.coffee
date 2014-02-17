sockjs     = require('sockjs')
Promise    = require('bluebird')
Jandal     = require('jandal')
xType      = require('xtype')
log        = require('log_')('Socket', 'yellow')
core       = require('../../core/api')

# Load xType validation
require('./controllers/validation')

# Setup Jandal
Jandal.handle('node')


# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

SOCKET_URL = '/socket'

CREATE  = 0
UPDATE  = 1
DESTROY = 2

TASK = 'task'
LIST = 'list'
PREF = 'pref'
INBOX = 'inbox'

# How long a connection has to authenticate itself before being kicked
TIMEOUT_AUTH = 3000

# What classnames can be edited
CLASSES = [TASK, LIST, PREF]


# -----------------------------------------------------------------------------
# Init
# -----------------------------------------------------------------------------

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
  websockets.installHandlers server, prefix: SOCKET_URL
  websockets.on 'connection', (socket) ->
    new GuestSocket(socket)


# -----------------------------------------------------------------------------
# Socket
# -----------------------------------------------------------------------------

class Socket

  ###
   * Socket
   *
   * - _socket (Socket) : a WebSocket connection
  ###

  constructor: (@_socket) ->
    @socket = new Jandal(@_socket)
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

  bindEvents: (action='on') =>
    return unless @events
    for name, methods of @events
      ns = @socket.namespace name
      for event in methods
        id = name + '_' + event
        fn = xType.guard(id, @[id], this)
        ns[action](event, fn)


  ###
   * Release
   *
   * Release control over the web socket.
   * This just unbinds all the events.
  ###

  release: =>
    @bindEvents('removeListener')


  ###
   * End
   *
   * Disconnect the socket from the server using the default status code and
   * error message.
  ###

  end: =>
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

  close: (status, message) =>
    @_socket.close(status, message)


# -----------------------------------------------------------------------------
# GuestSocket
# -----------------------------------------------------------------------------

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

  constructor: (socket) ->
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

  user_auth: (@userId, token, fn) =>
    clearTimeout(@authTimeout)
    core.checkTicket(ticket)
    .then => @login(fn)
    .catch => @kick()

  ###
   * (Private) User Login
   *
   * This handles logging in a user after they have been authenticated.
   * It releases control of the Jandal instance and then creates a new
   * UserSocket. If an error occurs, the socket will be closed.
   *
   * - fn (callback)
  ###

  login: (fn) =>
    socket = @_socket
    @release()
    core.getUser(@userId)
    .then (user) ->
      new UserSocket(socket, user)
    .catch (err) =>
      log.warn err
      @kick(err)

  ###
   * (Private) Kick
   *
   * This will close a socket because authentication has failed.
   *
   * [message] (string) : Optional error message
  ###

  kick: (message='err_bad_token') =>
    @close(3002, message)


  ###
   * (Private) Timeout
   *
   * This will close a socket because no attempt was made to authenticate
   * within the time limit.
  ###

  timeout: =>
    @close(1002, 'err_auth_timeout')


# -----------------------------------------------------------------------------
# UserSocket
# -----------------------------------------------------------------------------

class UserSocket extends Socket

  # Websocket events
  events:
    queue: ['sync']
    user: ['info']
    list: ['create', 'update', 'destroy', 'fetch']
    task: ['create', 'update', 'destroy', 'fetch']
    pref: ['update', 'fetch']

  constructor: (socket, @user) ->
    super
    log 'A user has been authenticated'
    @authenticated = true
    @socket.join(@user.id)
    @sync = new core.Sync(@user)
    core.analytics('socket.login', @user.id)


  broadcast: (event, arg1, arg2, arg3) =>
    core.analytics(event, @user.id)
    @socket.broadcast.to(@user.id).emit(event, arg1, arg2, arg3)


  ###
   * User Info
   *
   * - fn (function)
  ###

  user_info: (fn) =>
    @user.info().then (info) ->
      fn null, info


  ###
   * Model Fetch
   *
   * - classname (string)
   * - fn (function)
  ###

  task_fetch: (fn) =>
    @user.exportTasks().then (info) -> fn null, info

  list_fetch: (fn) =>
    @user.exportLists().then (info) -> fn null, info

  pref_fetch: (fn) =>
    @user.exportPref().then (info) -> fn null, info


  ###
   * Model Create
   *
   * - model (object)
   * - fn (function)
   * - [time] (number)
  ###

  create: (classname, model, fn, time) =>
    @sync[classname + '_create'](model, time)
    .then (id) =>
      @broadcast classname + '.create', model
      if fn then fn(null, id)
      return id
    .catch ->
      if fn then fn(true)

  task_create: (model, fn, time) =>
    @create(TASK, model, fn, time)

  list_create: (model, fn, time) =>
    @create(LIST, model, fn, time)


  ###
   * Model Update
   *
   * - model (object)
   * - [fn] (function)
  ###

  update: (classname, model, fn, time) =>
    @sync[classname + '_update'](model, time)
    .then (model) =>
      @broadcast classname + '.update', model
      if fn then fn(null)
    .catch (err) ->
      if fn then fn(true)


  task_update: (model, fn, time) =>
    @update(TASK, model, fn, time)

  list_update: (model, fn, time) =>
    @update(LIST, model, fn, time)

  pref_update: (model, fn, time) =>
    @update(PREF, model, fn, time)


  ###
   * Model Destroy
   *
   * - model (object)
   * - [fn] (function)
  ###

  destroy: (classname, model, fn, time) =>
    id = model.id
    @sync[classname + '_destroy'](id, time)
    .then =>
      @broadcast classname + '.destroy', id: id
      if fn then fn(null)
    .catch (err) ->
      if fn then fn(true)


  task_destroy: (model, fn, time) =>
    @destroy TASK, model, fn, time

  list_destroy: (model, fn, time) =>
    @destroy LIST, model, fn, time


  ###
   * Queue Sync
   *
   * Runs a batch of events
   * Returns an export of all the users tasks, lists and preferences
  ###

  merge_queue: (queue, clientTime, fn) =>
    @sync.queue(queue, clientTime)
    .then (results) -> fn(null, results)
    .catch (err) -> if fn then fn(true)

module.exports =
  init: init
