request  = require 'supertest'
should   = require 'should'
setup    = require '../setup'
app      = require '../../app/controllers/router'

describe 'Route -> Registration', ->

  before setup

# -----------------------------------------------------------------------------
# Registration
# -----------------------------------------------------------------------------

  describe '#registration', ->

    it 'should be able to register a user', (done) ->
      request(app)
        .post('/register')
        .send( name: 'George', email: 'example@email.com', password: 'password' )
        .end (err, res) ->
          [id, token] = JSON.parse res.text
          id.should.be.a.Number
          token.should.be.a.String
          token.should.match /^[a-f0-9]{64}$/
          done()

    it 'should not let users register with an email address already in use', (done) ->
      request(app)
        .post('/register')
        .send( name: 'Jono', email: 'example@email.com', password: 'password' )
        .expect('err_old_email', done )

# -----------------------------------------------------------------------------
# Validation
# -----------------------------------------------------------------------------

  describe '#validation', ->

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
