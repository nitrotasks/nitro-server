should   = require 'should'
Q        = require 'kew'
setup    = require './setup'
Auth     = require '../app/controllers/auth'

log = console.log.bind(console)

describe 'Auth API', ->

  before setup

  data =
    email: 'user@nitrotasks.com'
    name: 'Mr. Nitro'
    password: 'password'

  token = null

# -----------------------------------------------------------------------------
# Crypto
# -----------------------------------------------------------------------------

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

  it 'should be able to register a user', (done) ->

    Auth.register(data.name, data.email, data.password)
      .then (_token) ->
        token = _token
        token.should.be.type 'string'
        token.should.have.length 22
        done()
      .fail(log)


  it 'should verify the registration', (done) ->

    Auth.verifyRegistration(token)
      .then (user) ->
        data.name.should.equal user.name
        data.email.should.equal user.email
        data.password.should.not.equal user.password
        done()
      .fail(log)


# -----------------------------------------------------------------------------
# Login
# -----------------------------------------------------------------------------

  it 'Login with real password', (done) ->

    Auth.login(data.email, data.password).then (info) ->
      [uid, token, email, name, pro] = info
      uid.should.be.type 'number'
      token.should.have.length 64
      email.should.be.type 'string'
      name.should.be.type 'string'
      pro.should.be.type 'number'
      done()
    .fail (log)

  it 'Login with wrong password', (done) ->

    Auth.login(data.email, 'hunter2').fail -> done()


# -----------------------------------------------------------------------------
# Tokens
# -----------------------------------------------------------------------------

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


  it 'should add a reset token for a user', (done) ->

    Auth.createResetToken(data.email)
    .then (token) ->
      token.should.have.length 22
      done()
    .fail(log)



