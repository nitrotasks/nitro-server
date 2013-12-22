request  = require 'supertest'
should   = require 'should'
setup    = require '../setup'
app      = require '../../app/controllers/router'

describe 'Route -> Login', ->

  before setup

  token = null

  data =
    name: 'George'
    email: 'example@email.com'
    password: 'password'

  it 'should register a new user', (done) ->

    request(app)
      .post('/register')
      .send( name: 'George', email: 'example@email.com', password: 'password' )
      .end (req, res) ->
        token = res.text.match(/\/(\w*)$/)[1]
        done()

  it 'should verify the user', (done) ->

    request(app)
      .get("/register/#{ token }")
      .expect('success', done)

  it 'should allow users to login', (done) ->

    request(app)
      .post('/login')
      .send( email: data.email, password: data.password )
      .end (err, res) ->
        [id, token, email, name, pro] = res.body
        token.should.have.length 64
        email.should.equal data.email
        name.should.equal data.name
        pro.should.equal 0
        done()

  it 'should not allow users to login with the incorrect password', (done) ->

    request(app)
      .post('/login')
      .send( email: data.email, password: 'hunter2' )
      .expect('err_bad_pass', done)

  it 'should not allow users to login with a non-existant email', (done) ->

    request(app)
      .post('/login')
      .send( email: 'random@thing.net', password: 'hunter2' )
      .expect('err_bad_pass', done)

