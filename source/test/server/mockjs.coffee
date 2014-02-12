{EventEmitter} = require 'events'

class Socket

  constructor: ->
    @vent = new EventEmitter()
    @open = true
    @on 'close', => @open = false

  on: (event, fn) =>
    @vent.on(event, fn)

  once: (event, fn) =>
    @vent.once(event, fn)

  off: (event, fn) =>
    @vent.removeListener(event, fn)

  emit: (event, args...) =>
    @vent.emit(event, args...)

  write: (data) =>
    @emit 'message', data

  reply: (args...) =>
    @emit 'data', args...

  end: =>
    if @open then @emit 'close'
    @vent.removeAllListeners()

  close: (status, message) =>
    if @open then @emit 'close', status, message

class Server

  installHandlers: ->

  on: (event, fn) ->
    switch event
      when 'connection'
        mockjs.connection = fn

mockjs =

  createServer: ->
    return new Server()

  createSocket: ->
    socket = new Socket()
    mockjs.connection(socket)
    return socket


module.exports = mockjs
