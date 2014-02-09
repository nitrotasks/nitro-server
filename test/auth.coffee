should   = require 'should'
Promise  = require 'bluebird'
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


    it 'should compare correctly', (done) ->

      real = 'hamburger'
      fake = 'Hamburger'

      Auth.hash(real)
        .then (hash) ->
          Auth.compare fake, hash
        .then (same) ->
          same.should.be.false
          done()

    it 'should generate random bytes', (done) ->

      size = 30

      Auth.randomBytes(size)
        .then (bytes) ->
          bytes.length.should.equal size
          done()


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


    it 'should verify the registration', (done) ->

      Auth.verifyRegistration(token)
        .then (user) ->
          user.info()
        .then (info) ->
          data.name.should.equal info.name
          data.email.should.equal info.email
          data.password.should.not.equal info.password
          done()


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

    it 'Login with wrong password', (done) ->

      Auth.login(data.email, 'hunter2').catch (err) ->
        err.should.equal 'err_bad_pass'
        done()


# -----------------------------------------------------------------------------
# Tokens
# -----------------------------------------------------------------------------

  describe 'Tokens', ->

    it 'should generate a random token', (done) ->

      Promise.all([
        Auth.randomToken 12
        Auth.randomToken 15
        Auth.randomToken 20
        Auth.randomToken 50
        Auth.randomToken 64
      ])
      .spread (t12, t15, t20, t50, t64) ->
        t12.should.have.length 12
        t15.should.have.length 15
        t20.should.have.length 20
        t50.should.have.length 50
        t64.should.have.length 64
        done()

# -----------------------------------------------------------------------------
# Reset Password
# -----------------------------------------------------------------------------

  describe 'Reset Password', ->

    it 'should add a reset token for a user', (done) ->

      Auth.createResetToken(data.email)
        .then (token) ->
          token.should.match(/^\d+_\w+$/)
          done()

    it 'should fail if email does not exist', (done) ->
      Auth.createResetToken('gibberish').catch (err) ->
        err.should.equal 'err_no_user'
        done()
