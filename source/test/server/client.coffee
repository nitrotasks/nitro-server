Sandal = require('jandal-log')

class Client

  constructor: ->
    @socket = new Sandal()
    @callback = true

    for group in ['queue', 'user', 'task', 'list', 'pref']
      for method, fn of @[group]
        @[group][method] = fn.bind(this)

  queue:

    sync: (queue, time) ->
      @socket.send 'queue.sync', queue, time

  user:

    auth: (id, token, fn) ->
      @socket.send 'user.auth', id, token, fn

    info: ->
      @socket.send 'user.info'

  task:

    fetch: ->
      @socket.send 'task.fetch'

    create: (model, ts) ->
      @socket.send 'task.create', model

    update: (model) ->
      @socket.send 'task.update', model

    destroy: (model) ->
      @socket.send 'task.destroy', model

  list:

    fetch: ->
      @socket.send 'list.fetch'

    create: (model) ->
      @socket.send 'list.create', model

    update: (model) ->
      @socket.send 'list.update', model

    destroy: (model) ->
      @socket.send 'list.destroy', model

  pref:

    fetch: ->
      @socket.send 'pref.fetch'

    update: (model) ->
      @socket.send 'pref.update', model


module.exports = Client
