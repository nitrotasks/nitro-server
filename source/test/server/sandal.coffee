Jandal = require('jandal')
{EventEmitter} = require 'events'

setup = ->

  Jandal.handle

    write: (socket, message) ->
      socket.emit('write', message)

    read: (socket, fn) ->
      socket.on 'read', fn

    close: (socket, fn) ->
      socket.on('close', fn)

    error: (socket, fn) ->
      socket.on('error', fn)

    open: (socket, fn) ->
      fn()


class Socket extends EventEmitter

  ###
   * EVENTS:
   *
   * - read : a message is being sent to the socket
   * - write : a message is being sent from the socket
   * - close : the socket is being closed
   *
  ###

  constructor: ->
    super
    @open = true

  pipe: (socket) =>

    @on 'close', (status, message) ->
      socket.close(status, message)

    @on 'write', (message) ->
      socket.emit('read', message)

    return socket


  end: =>
    @close()

  close: (status, message) =>
    return unless @open
    @open = false
    @emit('close', status, message)



class Sandal

  @setup: setup

  constructor: ->

    @id = Math.floor(Math.random() * 1000)

    @serverSocket = new Socket()
    @serverSocket.name = 'server_' + @id

    @clientSocket = new Socket()
    @clientSocket.name = 'client_' + @id

    @serverSocket.pipe(@clientSocket).pipe(@serverSocket)
    @jandal = new Jandal(@clientSocket)

    @on('socket.close', @end)

  on: (event, fn) ->
    @jandal.on(event, fn)

  emit: (event, arg1, arg2, arg3) ->
    @jandal.emit(event, arg1, arg2, arg3)

  end: =>
    @clientSocket.end()
    @serverSocket.end()

    @clientSocket.removeAllListeners()
    @serverSocket.removeAllListeners()

module.exports = Sandal
