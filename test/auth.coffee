assert = require 'assert'
Auth = require '../app/auth'

data =
  email: 'george@czabania.com'
  name: 'George Czabania'
  password: 'password'

global = {}

describe 'Auth API', ->

  it 'should be able to register a user', (done) ->
    Auth.register(data.name, data.email, data.password)
      .then (token) ->
        # Should return the token
        global.token = token
        assert.equal typeof token, 'string'
        assert.equal token.length, 22
        done()
      .fail (err) ->
        throw err

  it 'should verify the user', (done) ->
    Auth.verifyRegistration(global.token)
      .then  -> done()

  it 'Login with real password', (done) ->
    Auth.login(data.email, data.password)
      .then -> done()
      .fail (err) ->
        throw err

  it 'Login with wrong password', (done) ->
    Auth.login(data.email, 'hunter2').fail ->
      done()

  it 'should generate a random token', ->
    token = Auth.createToken(64)
    assert.equal token.length, 64

