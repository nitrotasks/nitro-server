should   = require('should')
Promise  = require('bluebird')
setup    = require('../setup')
Auth     = require('../../core/controllers/auth')
Users    = require('../../core/models/users')

describe 'Auth', ->

  before (done) ->
    setup()
    .then(setup.createUser)
    .then -> done()
    .done()

# -----------------------------------------------------------------------------
# Crypto
# -----------------------------------------------------------------------------

  describe '#crypto', ->

    it 'should hash some data', (done) ->

      string = JSON.stringify
        this: 'is'
        some: 'random'
        data: 'that'
        i: 'made'

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

  describe '#register', ->

    user =
      name: 'Jimmy'
      email: 'jim@jimbo.com'
      pass: 'my-secret-passphrase'

    it 'should throw err_bad_name when registering', (done) ->

      Auth.register('', user.email, user.pass).catch (err) ->
        err.should.equal 'err_bad_name'
        done()

    it 'should throw err_bad_email when registering', (done) ->

      Auth.register(user.name, '', user.pass).catch (err) ->
        err.should.equal 'err_bad_email'
        done()

    it 'should throw err_bad_pass when registering', (done) ->

      Auth.register(user.name, user.email, '').catch (err) ->
        err.should.equal 'err_bad_pass'
        done()

    it 'should be able to register a user', (done) ->

      Auth.register(user.name, user.email, user.pass).spread (id, token) ->
        id.should.be.a.Number
        token.should.be.a.String
        token.should.match /^[a-f0-9]+$/
        done()

# -----------------------------------------------------------------------------
# Login
# -----------------------------------------------------------------------------

  describe '#login', ->

    it 'should return the user id and token', (done) ->

      Auth.login(_user.email, _user.password).spread (id, token) ->
        id.should.be.a.Number
        token.should.be.a.String
        token.should.have.length 64
        done()

    it 'should throw err if password does not match email', (done) ->

      Auth.login(_user.email, 'hunter2').catch (err) ->
        err.should.equal 'err_bad_pass'
        done()


# -----------------------------------------------------------------------------
# Tokens
# -----------------------------------------------------------------------------

  describe '#randomToken', ->

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

  describe '#createResetToken', ->

    it 'should add a reset token for a user', (done) ->

      Auth.createResetToken(_user.email)
        .then (token) ->
          token.should.match(/^\d+_\w+$/)
          done()

    it 'should fail if email does not exist', (done) ->
      Auth.createResetToken('gibberish').catch (err) ->
        err.should.equal 'err_no_user'
        done()
