sockjs = require 'sockjs'
Jandal = require 'jandal'
Sync = require '../controllers/sync'
Storage = require '../controllers/storage'
Log = require '../utils/log'
type = require '../utils/type'

log = Log 'Socket', 'yellow'
Jandal.handle 'node'


# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

CLIENT_ID = 'c'

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

init = (server, sjs=sockjs) ->
  websockets = sjs.createServer()
  websockets.installHandlers server, prefix: SOCKET_URL
  websockets.on 'connection', (socket) ->
    new GuestSocket(socket)


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
    user: ['info']
    model: ['sync']
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
    fn
      name: @user.name
      email: @user.email
      pro: @user.pro


  ###
   * Model Fetch
   *
   * - classname (string)
   * - fn (function)
  ###

  task_fetch: (fn) => fn @user.exportModel TASK
  list_fetch: (fn) => fn @user.exportModel LIST
  pref_fetch: (fn) => fn @user.exportModel PREF


  ###
   * Model Create
   *
   * - classname (string)
   * - model (object)
   * - fn (function)
  ###

  task_create: (model, fn) =>
    id = @sync.create(TASK, model)
    @broadcast 'task.create', model
    if type.function(fn) then fn(null, id)
    return id

  list_create: (model, fn) =>
    id = @sync.create(LIST, model)
    @broadcast 'list.create', model
    if type.function(fn) then fn(null, id)
    return id


  ###
   * Model Update
   *
   * - classname (string)
   * - model (object)
   * - [fn] (function)
  ###

  task_update: (model, time, fn) =>
    model = @sync.update TASK, model, time
    if model then @broadcast 'task.update', model
    if type.function(fn) then fn(null)

  list_update: (model, time, fn) =>
    model = @sync.update LIST, model, time
    if model then @broadcast 'list.update', model
    if type.function(fn) then fn(null)

  pref_update: (model, time, fn) =>
    model = @sync.update PREF, model, time
    if model then @broadcast 'pref.update', model
    if type.function(fn) then fn(null)


  ###
   * Model Destroy
   *
   * - classname (string)
   * - id (string)
   * - [fn] (function)
  ###

  task_destroy: (id, fn) =>
    @sync.destroy TASK, id
    @broadcast 'task.destroy', id
    if type.function(fn) then fn(null)

  list_destroy: (id, fn) =>
    @sync.destroy LIST, id
    @broadcast 'list.destroy', id
    if type.function(fn) then fn(null)


  ###
   * Model Sync
   *
   * - queue (object)
   * - fn (function)
  ###

  model_sync: (queue, fn) =>

    # Map client IDs to server IDs -- for lists only
    lists = {}

    # LISTS

    if queue.list
      for id, [event, list, time] of queue.list
        switch event

          when CREATE

            if type.array list.tasks
              tasks = list.tasks
              for taskId, i in tasks by -1 when taskId[0] is CLIENT_ID
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

    if type.function(fn) then fn(
      null,
      @user.exportModel(LIST)
      @user.exportModel(TASK)
      @user.exportModel(PREF)
    )

module.exports =
  init: init
