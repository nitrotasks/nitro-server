request  = require 'supertest'
should   = require 'should'
setup    = require '../../setup'
app      = require '../../../server/controllers/router'

describe 'Route -> Login', ->

  before setup

  data =
    name: 'George'
    email: 'example@email.com'
    password: 'password'

  it 'should register a new user', (done) ->

    request(app)
      .post('/register')
      .send( name: 'George', email: 'example@email.com', password: 'password' )
      .end (req, res) ->
        [id, token] = JSON.parse res.text
        id.should.be.a.Number
        token.should.be.a.String
        token.should.match /^[a-f0-9]{64}$/
        done()

  it 'should allow users to login', (done) ->

    request app
      .post '/login'
      .send email: data.email, password: data.password
      .end (err, res) ->
        [id, token] = res.body
        id.should.be.a.Number
        token.should.be.a.String
        token.should.match /^[a-f0-9]{64}$/
        done()

  it 'should not allow users to login with the incorrect password', (done) ->

    request app
      .post '/login'
      .send email: data.email, password: 'hunter2'
      .expect 'err_bad_pass', done

  it 'should not allow users to login with a non-existant email', (done) ->

    request app
      .post '/login'
      .send email: 'random@thing.net', password: 'hunter2'
      .expect 'err_bad_pass', done

