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
    @user.info().then (info) -> fn(null, info)


  ###
   * Model Fetch
   *
   * - classname (string)
   * - fn (function)
  ###

  fetch: (classname, fn) ->
    @user[classname].all()
    .then (info) -> fn(null, info)
    .catch (err) -> fn(err)

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

  create: (classname, data, fn, time) ->
    @sync[classname].create(data, time)
    .then (model) =>
      @broadcast(classname + '.create', model)
      fn(null, model)
      return model
    .catch (err) ->
      log.warn(err)
      fn(true)

  task_create: (data, fn, time) ->
    @create(TASK, data, fn, time)

  list_create: (data, fn, time) ->
    @create(LIST, data, fn, time)


  ###
   * Model Update
   *
   * - model (object)
   * - [fn] (function)
  ###

  update: (classname, id, data, fn, time) ->
    @sync[classname].update(id, data, time)
    .then (model) =>
      @broadcast(classname + '.update', id, data)
      if fn then fn(null, model)
    .catch (err) ->
      log.warn(err)
      if fn then fn(err)


  task_update: (id, model, fn, time) ->
    @update(TASK, id, model, fn, time)

  list_update: (id, model, fn, time) ->
    @update(LIST, id, model, fn, time)

  pref_update: (model, fn, time) ->
    @update(PREF, null, model, fn, time)


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
      @broadcast(classname + '.destroy', { id })
      if fn then fn(null, true)
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
