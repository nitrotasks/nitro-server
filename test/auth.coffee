should   = require 'should'
Q        = require 'kew'
setup    = require './setup'
Auth     = require '../app/controllers/auth'
Log      = require '../app/utils/log'

log = Log 'auth - test'

describe 'Auth API', ->

  before setup

  data =
    email: 'user@nitrotasks.com'
    name: 'Mr. Nitro'
    password: 'password'


# -----------------------------------------------------------------------------
# Crypto
# -----------------------------------------------------------------------------

  describe 'Crypto', ->

    it 'should hash some data', (done) ->

      string = JSON.stringify data

      Auth.hash(string)
        .then (hash) ->
          Auth.compare(string, hash)
        .then (same) ->
          same.should.be.true
          done()
        .fail(log)


    it 'should compare correctly', (done) ->

      real = 'hamburger'
      fake = 'Hamburger'

      Auth.hash(real)
        .then (hash) ->
          Auth.compare fake, hash
        .then (same) ->
          same.should.be.false
          done()
        .fail(log)

    it 'should generate random bytes', (done) ->

      size = 30

      Auth.randomBytes(size)
        .then (bytes) ->
          bytes.length.should.equal size
          done()
        .fail(log)


# -----------------------------------------------------------------------------
# Registration
# -----------------------------------------------------------------------------

  describe 'Registration', ->

    token = null

    it 'should be able to register a user', (done) ->

      Auth.register(data.name, data.email, data.password)
        .then (_token) ->
          token = _token
          token.should.be.type 'string'
          token.should.match(/^\d+_\w+$/)
          done()
        .fail(log)


    it 'should verify the registration', (done) ->

      Auth.verifyRegistration(token)
        .then (user) ->
          user.info()
        .then (info) ->
          data.name.should.equal info.name
          data.email.should.equal info.email
          data.password.should.not.equal info.password
          done()
        .fail(log)


# -----------------------------------------------------------------------------
# Login
# -----------------------------------------------------------------------------

  describe 'Login', ->

    it 'Login with real password', (done) ->

      Auth.login(data.email, data.password).then (info) ->
        [uid, token] = info
        uid.should.be.type 'number'
        token.should.have.length 64
        done()
      .fail (log)

    it 'Login with wrong password', (done) ->

      Auth.login(data.email, 'hunter2').fail -> done()


# -----------------------------------------------------------------------------
# Tokens
# -----------------------------------------------------------------------------

  describe 'Tokens', ->

    it 'should generate a random token', (done) ->

      Q.all([
        Auth.createToken 12
        Auth.createToken 15
        Auth.createToken 20
        Auth.createToken 50
        Auth.createToken 64
      ])
      .then ([t12, t15, t20, t50, t64]) ->
        t12.should.have.length 12
        t15.should.have.length 15
        t20.should.have.length 20
        t50.should.have.length 50
        t64.should.have.length 64
        done()
      .fail(log)

# -----------------------------------------------------------------------------
# Reset Password
# -----------------------------------------------------------------------------

  describe 'Reset Password', ->

    it 'should add a reset token for a user', (done) ->

      Auth.createResetToken(data.email)
        .then (token) ->
          token.should.match(/^\d+_\w+$/)
          done()
        .fail(log)

    it 'should fail if email does not exist', (done) ->
      Auth.createResetToken('gibberish').fail ->
          done()




