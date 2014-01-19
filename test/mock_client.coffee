# Generate strings for Jandal

timestamps = (obj) ->
  time = {}
  for key of obj when key isnt 'id'
    time[key] = client.timestamp()
  return time

emit = (event, args...) ->
  string = event

  if client.no_ts
    args = args[0...-1]

  string += '('
  string += JSON.stringify(args)[1...-1]
  string += ')'

  if client.callback
    string += '.fn('
    string += ++client.id
    string += ')'

  if client.socket
    client.socket.reply string

  return string

client =

  id: -1
  callback: true
  socket: null
  timestamp: -> return Date.now()

  setId: (id) ->
    client.id = id - 1

  queue:

    sync: (queue) ->
      emit 'queue.sync', queue

  user:

    auth: (id, token) ->
      emit 'user.auth', id, token

    info: ->
      emit 'user.info'

  task:

    fetch: ->
      emit 'task.fetch'

    create: (model, ts) ->
      emit 'task.create', model, client.timestamp()

    update: (model) ->
      emit 'task.update', model, timestamps(model)

    destroy: (model) ->
      emit 'task.destroy', model, client.timestamp()

  list:

    create: (model) ->
      emit 'list.create', model, client.timestamp()

    update: (model) ->
      emit 'list.update', model, timestamps(model)

    destroy: (model) ->
      emit 'list.destroy', model, client.timestamp()

  pref:

    update: (model) ->
      emit 'pref.update', model, timestamps(model)


module.exports = client
