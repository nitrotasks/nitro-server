assert = require "assert"
Auth = require "../app/auth"

data =
  username: "stayradiated"
  email: "george@czabania.com"
  password: "password"

describe "Auth ->", ->

  it "Register user", (done) ->
    Auth.register(data.username, data.email, data.password)
      .fail( -> console.log arguments )
      .then (user) ->
        assert.equal "stayradiated", data.username
        assert.equal "george@czabania.com", user.email
        done()

  it "Login with real password", (done) ->
    Auth.login(data.username, data.password)
      .fail( -> console.log arguments )
      .then (success) ->
        assert.equal success, yes
        done()

  it "Login with wrong password", (done) ->
    Auth.login(data.username, "hunter1")
      .fail( -> console.log arguments)
      .then (success) ->
        assert.equal success, no
        done()

