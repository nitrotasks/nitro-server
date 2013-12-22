request  = require 'supertest'
should   = require 'should'
setup    = require '../setup'
app      = require '../../app/controllers/router'

describe 'Route -> Registration', ->

  before setup

# -----------------------------------------------------------------------------
# Registration
# -----------------------------------------------------------------------------

  token = null
  oldToken = null

  it 'should be able to register a user', (done) ->
    request(app)
      .post('/register')
      .send( name: 'George', email: 'example@email.com', password: 'password' )
      .end (err, res) ->
        token = res.text.match(/\/(\w*)$/)[1]
        token.length.should.equal 22
        done()


  it 'should allow users to register with a duplicate email address', (done) ->
    request(app)
      .post('/register')
      .send( name: 'Jono', email: 'example@email.com', password: 'password' )
      .end (err, res) ->
        altToken = res.text.match(/\/(\w*)$/)[1]
        altToken.length.should.equal 22
        done()

  it 'should verify the token and add the user', (done) ->
    request(app)
      .get("/register/#{ token }")
      .expect('success', done )

  it 'should not let users register with an email address already in use', (done) ->
    request(app)
      .post('/register')
      .send( name: 'Jono', email: 'example@email.com', password: 'password' )
      .expect('err_old_email', done )

  it 'should not allow users to use a token for an old email address', (done) ->
    # Example: A user signs up twice with the same email adrress
    # They will get two tokens. When they sign up with one, the other one
    # should no longer work
    request(app)
      .get("/register/#{ oldToken }")
      .expect('error', done)

  it 'should not allow users to use a token that do not exist', (done) ->
    # Example: The token has been used or expired or never existed
    request(app)
      .get("/register/#{ token }")
      .expect('error', done)


# -----------------------------------------------------------------------------
# Validation
# -----------------------------------------------------------------------------

  it 'should require users to have a name', (done) ->
    request(app)
      .post('/register')
      .send( email: 'example@email.com', password: 'password')
      .expect( 'err_bad_name', done )

  it 'should require users to have a valid email', (done) ->
    request(app)
      .post('/register')
      .send( name: 'George', password: 'password')
      .expect( 'err_bad_email', done )

  it 'should require users to have a password', (done) ->
    request(app)
      .post('/register')
      .send( name: 'George', email: 'example@email.com')
      .expect( 'err_bad_pass', done )

  it 'should not crash if nothing is sent', (done) ->
    request(app)
      .post('/register')
      .send()
      .expect( 'err_bad_name', done )
