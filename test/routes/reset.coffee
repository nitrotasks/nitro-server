request  = require 'supertest'
should   = require 'should'
setup    = require '../setup'
app      = require '../../app/controllers/router'

describe 'Route -> Reset', ->

  before setup

  resetToken = null
  registerToken = null
  newPassword = 'xkcd'

  data =
    name: 'George'
    email: 'example@email.com'
    password: 'password'

  it 'should register a new user', (done) ->

    request(app)
      .post('/register')
      .send(data)
      .end (req, res) ->
        registerToken = res.text.match(/\/(\w*)$/)[1]
        registerToken.should.match /^\d+_\w+$/
        done()

  it 'should verify the user', (done) ->

    request(app)
      .get("/register/#{ registerToken }")
      .expect('success', done)

  it 'should display the reset page', (done) ->

    request(app)
      .get('/reset')
      .expect(200, done)

  it 'should allow users to reset their password', (done) ->

    request(app)
      .post('/reset')
      .send( email: data.email )
      .end (err, res) ->
        res.text.should.not.equal 'err_bad_email'
        resetToken = res.text
        resetToken.should.match /^\d+_\w+$/
        resetToken.match(/[^_]*$/)[0].length.should.equal 22
        done()

  it 'should fail if the email address does not exist', (done) ->

    request(app)
      .post('/reset')
      .send( email: 'not.an@email.com' )
      .expect( 'error', done )

  it 'should allow the user to use a token', (done) ->

    request(app)
      .get("/reset/#{ resetToken }")
      .expect(200, done)

  it 'should fail if the token doesn\'t exist', (done) ->

    request(app)
      .get('/reset/somesillytoken')
      .expect('error', done)

  it 'should force the user to have matching passwords', (done) ->

    request(app)
      .post("/reset/#{ resetToken }")
      .send(
        password: newPassword
        passwordConfirmation: 'test'
      )
      .expect(401, done)

  it 'should reset the password', (done) ->

    request(app)
      .post("/reset/#{ resetToken }")
      .send(
        password: newPassword
        passwordConfirmation: newPassword
      )
      .expect(200, done)

  it 'should not be able to use the same token twice', (done) ->

    request(app)
      .post("/reset/#{ resetToken }")
      .send(
        password: 'hacker'
        passwordConfirmation: 'hacker'
      )
      .expect(401, done)

  it 'should be able to login with the new password', (done) ->

    request(app)
      .post("/login")
      .send(
        email: data.email
        password: newPassword
      )
      .expect(200, done)

