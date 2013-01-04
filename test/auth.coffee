assert = require "assert"
Auth = require "../app/auth"

data =
  email: "george@czabania.com"
  name: "George Czabania"
  password: "password"

describe "Auth ->", ->

  it "Register user", (done) ->
    Auth.register(data.name, data.email, data.password)
      .fail( -> console.log arguments )
      .then (user) ->
        assert.equal "George Czabania", data.name
        assert.equal "george@czabania.com", user.email
        done()

  it "Login with real password", (done) ->
    Auth.login(data.email, data.password)
      .fail( -> console.log arguments )
      .then (success) ->
        assert.equal success, yes
        done()

  it "Login with wrong password", (done) ->
    Auth.login(data.email, "hunter2")
      .fail( -> console.log arguments)
      .then (success) ->
        assert.equal success, no
        done()

