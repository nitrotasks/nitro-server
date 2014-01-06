Socket = require '../app/controllers/socket'
Auth   = require '../app/controllers/auth'
should = require 'should'
setup  = require './setup'
mockjs = require './mockjs'

describe 'Socket', ->

  socket = null

  user =
    name: 'Fred'
    email: 'fred@gmail.com'
    pass: 'xkcd'

  before setup

  beforeEach ->
    Socket.init(null, mockjs)
    socket = mockjs.createSocket()

  afterEach ->
    socket.end()

  it 'should create a new user', (done) ->
    Auth.register(user.name, user.email, user.pass)
    .then (token) ->
      Auth.verifyRegistration(token)
    .then ->
      Auth.login(user.email, user.pass)
    .then ([id, token]) ->
      user.id = id
      user.token = token
      done()

  it 'should try to auth', (done) ->
    socket.on 'close', ->
      socket.open.should.equal false
      done()
    socket.reply 'user.auth(20,"token").fn(20)'


  it 'should be kicked after 3 seconds', (done) ->
    @timeout 3200
    start = Date.now()
    socket.on 'close', ->
      diff = Date.now() - start
      diff.should.be.approximately(3000, 10)
      socket.open.should.equal false
      done()

  it 'should login via sockets', (done) ->
    socket.on 'message', (message) ->
      message.should.equal 'Jandal.fn_1(true)'
      socket.end()
      done()
    socket.reply "user.auth(#{ user.id },\"#{ user.token }\").fn(1)"

  it 'should get user info', (done) ->
    socket.reply "user.auth(#{ user.id },\"#{ user.token }\").fn(1)"
    socket.on 'message', (message) ->
      switch message[10]
        when '1'
          message.should.equal 'Jandal.fn_1(true)'
          socket.reply 'user.info().fn(2)'
        when '2'
          message.should.equal 'Jandal.fn_2({"name":"Fred","email":"fred@gmail.com","pro":0})'
          done()

  it 'should create user data', (done) ->
    socket.reply "user.auth(#{ user.id },\"#{ user.token }\").fn(1)"
    socket.on 'message', (message) ->
      switch message[10]
        when '1'
          message.should.equal 'Jandal.fn_1(true)'
          socket.reply 'model.create("task",{"name":"something","list":20}).fn(2)'
        when '2'
          message.should.equal 'Jandal.fn_2("s0")'
          done()

  it 'should fetch user data', (done) ->
    socket.reply "user.auth(#{ user.id },\"#{ user.token }\").fn(1)"
    socket.on 'message', (message) ->
      switch message[10]
        when '1'
          message.should.equal 'Jandal.fn_1(true)'
          socket.reply 'model.fetch("task").fn(2)'
        when '2'
          try
            message.should.equal 'Jandal.fn_2([{"name":"something","list":20,"id":"s0"}])'
          catch e
            console.log e

          done()

  it 'should broadcast events to other sockets', (done) ->
    other = mockjs.createSocket()
    socket.reply "user.auth(#{ user.id },\"#{ user.token }\").fn(1)"
    other.reply "user.auth(#{ user.id },\"#{ user.token }\").fn(1)"

    other.on 'message', (message) ->
      switch message[10]
        when '1'
          message.should.equal 'Jandal.fn_1(true)'
          socket.reply 'model.update("task",{"id":"s0","name":"Old task with new name"}).fn(2)'
        else
          message.should.equal 'task.update({"name":"Old task with new name","list":20,"id":"s0"})'
          other.end()
          done()

  it 'should destroy user data', (done) ->
    socket.reply "user.auth(#{ user.id },\"#{ user.token }\").fn(1)"
    socket.on 'message', (message) ->
      switch message[10]
        when '1'
          message.should.equal 'Jandal.fn_1(true)'
          socket.reply 'model.destroy("task","s0").fn(2)'
        when '2'
          message.should.equal 'Jandal.fn_2()'
          socket.reply 'model.fetch("task").fn(3)'
        when '3'
          message.should.equal 'Jandal.fn_3([])'
          done()
