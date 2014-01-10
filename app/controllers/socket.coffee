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

  # Websocket events
  events:
    user: ['auth']

  constructor: (socket) ->
    super
    log 'A new guest has connected'
    @authenticated = false
    @_timeout = setTimeout @timeout, TIMEOUT_AUTH

  user_auth: (@userId, token, fn) =>
    Storage.checkLoginToken(@userId, token)
      .then (exists) =>
        if exists
          @login(fn)
        else
          fn(false)
          @end()
      .fail (err) =>
        log err
        @end()

  login: (callback) =>
    socket = @_socket
    @release()
    Storage.get(@userId)
      .then (user) =>
        clearTimeout @_timeout
        new UserSocket(socket, user)
        callback(true)
      .fail (err) =>
        log err
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
    log 'Broadcasting', event, arg1, arg2, arg3
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
    if type.function(fn) then fn(id)
    return id

  list_create: (model, fn) =>
    id = @sync.create(LIST, model)
    @broadcast 'list.create', model
    if type.function(fn) then fn(id)
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
    if type.function(fn) then fn()

  list_update: (model, time, fn) =>
    model = @sync.update LIST, model, time
    if model then @broadcast 'list.update', model
    if type.function(fn) then fn()

  pref_update: (model, time, fn) =>
    model = @sync.update PREF, model, time
    if model then @broadcast 'pref.update', model
    if type.function(fn) then fn()


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
    if type.function(fn) then fn()

  list_destroy: (id, fn) =>
    @sync.destroy LIST, id
    @broadcast 'list.destroy', id
    if type.function(fn) then fn()


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
      for id, items of queue.list
        for [event, model, time] in items
          switch event

            when CREATE
              model.id = id
              lists[id] = @list_create model, time

            when UPDATE
              @list_update model, time

            when DESTROY
              @list_destroy model, time

    console.log 'pre_data', @user.exportModel LIST

    # TASKS

    if queue.task
      for id, items of queue.task
        for [event, model, time] in items
          switch event

            when CREATE
              if lists[model.listId]
                model.listId = lists[model.listId]
              @task_create model, time

            when UPDATE
              if model.list and lists[model.listId]
                model.listId = lists[model.listId]
              @task_update model, time

            when DESTROY
              @task_destroy model, time

    # PREFS

    if queue.pref
      for id, items of queue.task
        for [event, model, time] in items
          switch event

            when UPDATE
              @pref_update model, time


    # CALLBACK

    if type.function(fn) then fn(
      @user.exportModel(TASK)
      @user.exportModel(LIST)
      @user.exportModel(PREF)
    )

module.exports =
  init: init
