assert = require "assert"
Auth = require "../app/auth"

data =
  email: "george@czabania.com"
  name: "George Czabania"
  password: "password"

describe "Auth API", ->

  it "sholud be able to register a user", (done) ->
    Auth.register(data.name, data.email, data.password)
      .fail( -> console.log arguments )
      .then (data) ->
        # Should return an array
        assert.equal Array.isArray(data), yes
        # The first part should be the userID
        assert.equal typeof parseInt(data[0], 10), "number"
        # The second part shuold be the token
        assert.equal typeof data[1], "string"
        assert.equal data[1].length, 64+29
        done()

  it "Login with real password", (done) ->
    Auth.login(data.email, data.password)
      .fail( -> console.log arguments )
      .then ->
        done()

  it "Login with wrong password", (done) ->
    Auth.login(data.email, "hunter2").fail ->
      done()

  it "should generate a random token", ->
    token = Auth.createToken(64)
    assert.equal token.length, 64

