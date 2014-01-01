{EventEmitter} = require 'events'

class Socket extends EventEmitter

  constructor: ->
    @open = true
    @on 'close', => @open = false

  write: (data) ->
    @emit 'message', data

  reply: (args...) ->
    @emit 'data', args...

  end: ->
    @emit 'close'

  close: (status, message) ->
    @emit 'close', status, message

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
