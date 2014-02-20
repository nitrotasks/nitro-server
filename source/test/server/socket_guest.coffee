should      = require('should')
setup       = require('../setup')
token       = require('../../server/controllers/token')
GuestSocket = require('../../server/sockets/guest')
Sandal      = require('./sandal')

describe 'GuestSocket', ->

  client = null
  socket = null

  before (done) ->
    setup()
    .then(setup.createUser)
    .then(Sandal.setup)
    .then -> done()
    .done()

  beforeEach ->
    client = new Sandal()
    socket = new GuestSocket(client.serverSocket)

  afterEach ->
    client.end()

  describe ':user.auth', ->

    it 'should throw err if token is invalid', (done) ->

      client.emit 'user.auth', 'token', (err, success) ->
        err.should.equal('err_bad_token')
        client.on 'socket.close', (status, message) ->
          status.should.equal(3002)
          message.should.equal('err_bad_token')
          done()

    it 'should throw err if user does not exist', (done) ->

      socketToken = token.createSocketToken(-1)

      client.emit 'user.auth', socketToken, (err, success) ->
        err.should.equal('err_bad_token')
        client.on 'socket.close', (status, message) ->
          status.should.equal(3002)
          message.should.equal('err_bad_token')
          done()

    it 'should disconnect after three seconds', (done) ->

      @timeout(4000)
      start = Date.now()

      client.on 'socket.close', ->
        (Date.now() - start).should.be.approximately(3000, 10)
        done()

    it 'should successfully login', (done) ->

      socketToken = token.createSocketToken(setup.userId)

      client.emit 'user.auth', socketToken, (err, user) ->
        should.equal(err, null)
        user.should.have.keys('id', 'name', 'email', 'pro', 'created_at')

        user.id.should.equal(setup.userId)
        user.name.should.equal(setup._user.name)
        user.email.should.equal(setup._user.email)
        user.pro.should.equal(setup._user.pro)
        user.created_at.should.be.a.Date

        done()
