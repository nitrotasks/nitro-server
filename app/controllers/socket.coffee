sockjs = require 'sockjs'
Jandal = require 'jandal'
xType = require 'xtype'
Sync = require '../controllers/sync'
Storage = require '../controllers/storage'
Validation = require '../controllers/validation'
Log = require '../utils/log'

log = Log 'Socket', 'yellow'
Jandal.handle 'node'


# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

SERVER_PREFIX = 's'

SOCKET_URL = '/socket'

CREATE  = 0
UPDATE  = 1
DESTROY = 2

TASK = 'task'
LIST = 'list'
PREF = 'pref'

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
    clearTimeout @authTimeout
    Storage.checkLoginToken(@userId, token)
      .then (exists) =>
        if exists
          @login(fn)
        else
          @kick()
      .fail (err) =>
        log err
        @kick(err)


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
    Storage.get(@userId)
      .then (user) =>
        new UserSocket(socket, user)
        fn(null, true)
      .fail (err) =>
        log err
        @kick(err)


  ###
   * (Private) Kick
   *
   * This will close a socket because authentication has failed.
   *
   * [message] (string) : Optional error message
  ###

  kick: (message='err_bad_token') =>
    @close 3002, message


  ###
   * (Private) Timeout
   *
   * This will close a socket because no attempt was made to authenticate
   * within the time limit.
  ###

  timeout: =>
    @close 1002, 'err_auth_timeout'


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
    @_socket.on 'close', @logout
    @socket.join(@user.id)
    @sync = new Sync(@user)

  broadcast: (event, arg1, arg2, arg3) =>
    @socket.broadcast.to(@user.id).emit(event, arg1, arg2, arg3)

  logout: =>
    # If the user is only logged in from one client then remove them from memory
    if Jandal.all.in(@user.id).length() is 0
      Storage.release @user.id


  ###
   * User Info
   *
   * - fn (function)
  ###

  user_info: (fn) =>
    fn null,
      name: @user.name
      email: @user.email
      pro: @user.pro


  ###
   * Model Fetch
   *
   * - classname (string)
   * - fn (function)
  ###

  task_fetch: (fn) => fn null, @user.exportModel TASK
  list_fetch: (fn) => fn null, @user.exportModel LIST
  pref_fetch: (fn) => fn null, @user.exportModel PREF


  ###
   * Model Create
   *
   * - model (object)
   * - time (number)
   * - fn (function)
  ###

  task_create: (model, time, fn) =>
    id = @sync.task_create(model, time)
    if id isnt null
      @broadcast 'task.create', model
      if fn then fn(null, id)
    else
      if fn then fn(true)
    return id

  list_create: (model, time, fn) =>
    id = @sync.list_create(model, time)
    if id isnt null
      @broadcast 'list.create', model
      if fn then fn(null, id)
    else
      if fn then fn(true)
    return id


  ###
   * Model Update
   *
   * - model (object)
   * - time (object)
   * - [fn] (function)
  ###

  task_update: (model, time, fn) =>
    model = @sync.task_update(model, time)
    if model
      @broadcast 'task.update', model
      if fn then fn(null)
    else
      if fn then fn(true)

  list_update: (model, time, fn) =>
    model = @sync.list_update(model, time)
    if model
      @broadcast 'list.update', model
      if fn then fn(null)
    else
      if fn then fn(true)

  pref_update: (model, time, fn) =>
    model = @sync.pref_update(model, time)
    if model
      @broadcast 'pref.update', model
      if fn then fn(null)
    else
      if fn then fn(true)


  ###
   * Model Destroy
   *
   * - model (object)
   * - time (number)
   * - [fn] (function)
  ###

  task_destroy: (model, time, fn) =>
    id = model.id
    if @sync.task_destroy(id, time)
      @broadcast 'task.destroy', id: id
      if fn then fn(null)
    else
      if fn then fn(true)

  list_destroy: (model, time, fn) =>
    id = model.id
    if @sync.list_destroy(id, time)
      @broadcast 'list.destroy', id: id
      if fn then fn(null)
    else
      if fn then fn(true)


  ###
   * Model Sync
   *
   * - queue (object)
   * - fn (function)
  ###

  queue_sync: (queue, fn) =>

    # Map client IDs to server IDs -- for lists only
    lists = {}

    # LISTS

    if queue.list
      for id, [event, list, time] of queue.list
        switch event

          when CREATE

            if xType.get('array')(list.tasks)
              tasks = list.tasks
              for taskId, i in tasks by -1 when taskId[0] isnt SERVER_PREFIX
                tasks.splice(i, 1)

            list.id = id
            lists[id] = @list_create list, time

          when UPDATE
            list.id = id
            @list_update list, time

          when DESTROY
            @list_destroy list, time

    # TASKS

    if queue.task
      for id, [event, task, time] of queue.task
        switch event

          when CREATE
            task.id = id
            if lists[task.listId]
              task.listId = lists[task.listId]
            @task_create task, time

          when UPDATE
            task.id = id
            if task.listId? and lists[task.listId]
              task.listId = lists[task.listId]
            @task_update task, time

          when DESTROY
            @task_destroy task, time

    # PREFS

    if queue.pref
      for id, [event, pref, time] of queue.task
        switch event

          when UPDATE
            @pref_update pref, time


    # CALLBACK

    if fn then fn null,
      list: @user.exportModel(LIST)
      task: @user.exportModel(TASK)
      pref: @user.exportModel(PREF)

module.exports =
  init: init
