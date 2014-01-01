Socket = require '../app/controllers/socket'
should = require 'should'
setup  = require './setup'
mockjs = require './mockjs'

describe 'Socket', ->

  socket = null

  before setup

  beforeEach ->
    Socket.init(null, mockjs)
    socket = mockjs.createSocket()

  it 'should try to auth', (done) ->
    socket.reply 'user.auth(20,"token","__fn__20")'
    socket.on 'message', (message) ->
      message.should.equal '__fn__20(false)'
    socket.on 'close', ->
      socket.open.should.equal false
      done()
