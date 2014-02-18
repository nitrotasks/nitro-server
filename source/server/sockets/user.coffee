Socket = require('../sockets/base')
core   = require('../../core/api')
log    = require('log_')('Socket -> user', 'green')


CREATE  = 0
UPDATE  = 1
DESTROY = 2

TASK = 'task'
LIST = 'list'
PREF = 'pref'
INBOX = 'inbox'

CLASSES = [TASK, LIST, PREF]


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


  broadcast: (event, arg1, arg2, arg3) ->
    core.analytics(event, @user.id)
    @socket.broadcast.to(@user.id).emit(event, arg1, arg2, arg3)


  ###
   * User Info
   *
   * - fn (function)
  ###

  user_info: (fn) ->
    @user.read().then (info) -> fn(null, info)


  ###
   * Model Fetch
   *
   * - classname (string)
   * - fn (function)
  ###

  fetch: (classname, fn) ->
    @user[classname].all()
    .then (info) -> fn(null, info)

  task_fetch: (fn) ->
    @fetch(TASK, fn)

  list_fetch: (fn) ->
    @fetch(LIST, fn)

  pref_fetch: (fn) ->
    @fetch(PREF, fn)


  ###
   * Model Create
   *
   * - model (object)
   * - fn (function)
   * - [time] (number)
  ###

  create: (classname, model, fn, time) ->
    @sync[classname].create(model, time)
    .then (id) =>
      @broadcast classname + '.create', model
      if fn then fn(null, id)
      return id
    .catch ->
      if fn then fn(true)

  task_create: (model, fn, time) ->
    @create(TASK, model, fn, time)

  list_create: (model, fn, time) ->
    @create(LIST, model, fn, time)


  ###
   * Model Update
   *
   * - model (object)
   * - [fn] (function)
  ###

  update: (classname, model, fn, time) ->
    @sync[classname].update(model, time)
    .then (model) =>
      @broadcast classname + '.update', model
      if fn then fn(null)
    .catch (err) ->
      if fn then fn(true)


  task_update: (model, fn, time) ->
    @update(TASK, model, fn, time)

  list_update: (model, fn, time) ->
    @update(LIST, model, fn, time)

  pref_update: (model, fn, time) ->
    @update(PREF, model, fn, time)


  ###
   * Model Destroy
   *
   * - model (object)
   * - [fn] (function)
  ###

  destroy: (classname, model, fn, time) ->
    id = model.id
    @sync[classname].destroy(id, time)
    .then =>
      @broadcast classname + '.destroy', id: id
      if fn then fn(null)
    .catch (err) ->
      if fn then fn(true)


  task_destroy: (model, fn, time) ->
    @destroy TASK, model, fn, time

  list_destroy: (model, fn, time) ->
    @destroy LIST, model, fn, time


  ###
   * Queue Sync
   *
   * Runs a batch of events
   * Returns an export of all the users tasks, lists and preferences
  ###

  merge_queue: (queue, clientTime, fn) ->
    @sync.queue(queue, clientTime)
    .then (results) -> fn(null, results)
    .catch (err) -> if fn then fn(true)


module.exports = UserSocket
