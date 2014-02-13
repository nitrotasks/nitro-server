sockjs     = require('sockjs')
Promise    = require('bluebird')
Jandal     = require('jandal')
xType      = require('xtype')
log        = require('log_')('Socket', 'yellow');

# Stuff that shouldn't be used
Sync       = require('../controllers/sync')
Users      = require('../controllers/users')
db         = require('../controllers/query')
Time       = require('../utils/time')

# Stuff that should be used
analytics  = require('../controllers/analytics')
Validation = require('../controllers/validation')


# Setup Jandal
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
    analytics 'socket.connect'


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
    db.login.exists(@userId, token)
      .then (exists) =>
        if exists
          @login(fn)
        else
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

  login: (fn) =>
    socket = @_socket
    @release()
    Users.read(@userId)
      .then (user) =>
        new UserSocket(socket, user)
        fn(null, true)
      .catch (err) =>
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
    @socket.join(@user.id)
    @sync = new Sync(@user)
    analytics 'socket.login', @user.id


  broadcast: (event, arg1, arg2, arg3) =>
    analytics event, @user.id
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
   * Model Sync
   *
   * - queue (object)
   * - clientTime (number) : time in seconds since 01/01/1970 12:00:00
   * - fn (function)
  ###

  queue_sync: (queue, clientTime, fn) =>

    # Calculate timezone difference between server and client
    offset = Time.now() - clientTime

    # Make a new promise so we can do all this sequentially
    pList = []
    pAll = []

    # PREFS

    if queue.pref
      for [event, pref, time] in queue.task

        Time.offset offset, time

        continue unless event is UPDATE
        pAll.push @pref_update(pref, null, time)


    # Map client IDs to server IDs -- for lists only
    lists = {}

    # LISTS

    if queue.list
      for [event, list, time] in queue.list

        Time.offset offset, time

        switch event

          when CREATE

            tasks = list.tasks

            for taskId, i in tasks by -1 when taskId < 0
              tasks.splice(i, 1)

            # Enclose list
            do =>
              id = list.id
              pList.push @list_create(list, null, time).then (_id) ->
                lists[id] = _id

          when UPDATE
            pAll.push @list_update list, null, time

          when DESTROY
            pAll.push @list_destroy list, null, time

    Promise.all(pList)
    .then =>

      # TASKS

      if queue.task

        for [event, task, time] in queue.task

          Time.offset offset, time

          if lists[task.listId]
            task.listId = lists[task.listId]

          switch event

            when CREATE
              pAll.push @task_create(task, null, time)

            when UPDATE
              pAll.push @task_update(task, null, time)

            when DESTROY
              pAll.push @task_destroy(task, null, time)


      Promise.all(pAll)

    .then =>

      unless fn then throw null

      Promise.all [
        @user.exportLists()
        @user.exportTasks()
        @user.exportPref()
      ]

    .spread (lists, tasks, pref) =>

      fn null,
        list: lists
        task: tasks
        pref: pref

    .catch ->
      return


module.exports =
  init: init
