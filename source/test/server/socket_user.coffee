should      = require('should')
setup       = require('../setup')
token       = require('../../server/controllers/token')
GuestSocket = require('../../server/sockets/guest')
Sandal      = require('./sandal')

describe 'UserSocket', ->

  client = null
  socket = null

  before (done) ->
    setup()
    .then(setup.createUser)
    .then(Sandal.setup)
    .then -> done()
    .done()

  beforeEach (done) ->

    sessionToken = token.createSocketToken(setup.userId)

    client = new Sandal()
    socket = new GuestSocket(client.serverSocket)

    client.emit 'user.auth', sessionToken, (err, user) ->
      should.equal(err, null)
      done()

  afterEach ->
    client.end()

  describe ':user.info', ->

    it 'should get user info', (done) ->

      client.emit 'user.info', (err, user) ->
        user.should.have.keys('id', 'name', 'email', 'pro', 'created_at')

        user.id.should.equal(setup.userId)
        user.name.should.equal(setup._user.name)
        user.email.should.equal(setup._user.email)
        user.pro.should.equal(setup._user.pro)
        user.created_at.should.be.a.Date

        done()
