assert = require 'assert'
Q = require 'kew'
Auth = require '../app/auth'
connect = require '../app/connect'
database = require '../app/database'

connect.init 'testing'

log = console.log.bind(console)

describe 'Auth API', ->

  data =
    email: 'george@czabania.com'
    name: 'George Czabania'
    password: 'password'

  token = null

# -----------------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------------

  before (done) ->

    promise = Q.all [
      connect.ready
      database.connected
    ]

    promise
      .then ->
        connect.redis.flushdb()
        database.truncate 'users'
      .then ->
        done()


  it 'should be able to register a user', (done) ->
    Auth.register(data.name, data.email, data.password)
      .then (_token) ->
        token = _token
        assert.equal typeof token, 'string'
        assert.equal token.length, 22
        done()
      .fail(log)

  it 'should verify the registration', (done) ->
    Auth.verifyRegistration(token).then (user) ->
      assert.equal data.name, user.name
      assert.equal data.email, user.email
      assert.notEqual data.password, user.password
      done()

  it 'Login with real password', (done) ->

    Auth.login(data.email, data.password).then (token) ->
      assert.equal token.length, 64
      done()
    .fail (log)

  it 'Login with wrong password', (done) ->

    Auth.login(data.email, 'hunter2').fail -> done()

  it 'should generate a random token', (done) ->

    Q.all([
      Auth.createToken 12
      Auth.createToken 15
      Auth.createToken 20
      Auth.createToken 50
      Auth.createToken 64
    ])
    .then ([t12, t15, t20, t50, t64]) ->
      assert.equal t12.length, 12
      assert.equal t15.length, 15
      assert.equal t20.length, 20
      assert.equal t50.length, 50
      assert.equal t64.length, 64
      done()
    .fail(log)


  it 'should add a reset token for a user', (done) ->

    Auth.createResetToken(data.email)
    .then (token) ->
      assert.equal token.length, 22
      done()
    .fail(log)

