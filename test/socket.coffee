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
    socket.reply 'user.auth(20,"token","__fn__20")'
    socket.on 'message', (message) ->
      message.should.equal '__fn__20(false)'
    socket.on 'close', ->
      socket.open.should.equal false
      done()

  it 'should be kicked after 3 seconds', (done) ->
    @timeout 3200
    start = Date.now()
    socket.on 'close', ->
      diff = Date.now() - start
      diff.should.be.approximately(3000, 10)
      socket.open.should.equal false
      done()

  it 'should login via sockets', (done) ->
    socket.reply "user.auth(#{ user.id },\"#{ user.token }\",\"__fn__1\")"
    socket.on 'message', (message) ->
      message.should.equal '__fn__1(true)'
      socket.end()
      done()

  it 'should get user info', (done) ->
    socket.reply "user.auth(#{ user.id },\"#{ user.token }\",\"__fn__1\")"
    socket.on 'message', (message) ->
      switch message[6]
        when '1'
          message.should.equal '__fn__1(true)'
          socket.reply 'user.info("__fn__2")'
        when '2'
          message.should.equal '__fn__2({"name":"Fred","email":"fred@gmail.com","pro":0})'
          done()

  it 'should create user data', (done) ->
    socket.reply "user.auth(#{ user.id },\"#{ user.token }\",\"__fn__1\")"
    socket.on 'message', (message) ->
      switch message[6]
        when '1'
          message.should.equal '__fn__1(true)'
          socket.reply 'model.create("task",{"name":"something","list":20},"__fn__2")'
        when '2'
          message.should.equal '__fn__2("s-0")'
          done()

  it 'should fetch user data', (done) ->
    socket.reply "user.auth(#{ user.id },\"#{ user.token }\",\"__fn__1\")"
    socket.on 'message', (message) ->
      switch message[6]
        when '1'
          message.should.equal '__fn__1(true)'
          socket.reply 'model.fetch("task","__fn__2")'
        when '2'
          message.should.equal '__fn__2([{"name":"something","list":20,"id":"s-0"}])'
          done()

  it 'should broadcast events to other sockets', (done) ->
    other = mockjs.createSocket()
    socket.reply "user.auth(#{ user.id },\"#{ user.token }\",\"__fn__1\")"
    other.reply "user.auth(#{ user.id },\"#{ user.token }\",\"__fn__1\")"

    other.on 'message', (message) ->
      switch message[6]
        when '1'
          message.should.equal '__fn__1(true)'
          socket.reply 'model.update("task",{"id":"s-0","name":"Old task with new name"},"__fn__2")'
        else
          message.should.equal 'task.update({"name":"Old task with new name","list":20,"id":"s-0"})'
          done()

