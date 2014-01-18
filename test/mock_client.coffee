# Generate strings for Jandal

socket = null
callback = 0

timestamps = (obj) ->
  time = {}
  for key of obj when key isnt 'id'
    time[key] = Date.now()
  return time

emit = (event, fn, args...) ->
  string = event
  string += '('
  string += JSON.stringify(args)[1...-1]
  string += ')'

  if fn
    string += '.fn('
    string += ++callback
    string += ')'

  if socket then socket.reply string

  return string

client =

  use: (_socket) ->
    socket = _socket

  reset: ->
    callback = 0

  queue:

    sync: (queue) ->
      emit 'queue.sync', true, queue

  user:

    auth: (id, token) ->
      emit 'user.auth', true, id, token

    info: ->
      emit 'user.info', true

  task:

    fetch: ->
      emit 'task.fetch', true

    create: (model) ->
      emit 'task.create', true, model, Date.now()

    update: (model) ->
      emit 'task.update', false, model, timestamps(model)

    destroy: (model) ->
      emit 'task.destroy', true, model, Date.now()

  list:

    create: (model) ->
      emit 'list.create', true, model, Date.now()

    update: ->

    destroy: ->


module.exports = client
