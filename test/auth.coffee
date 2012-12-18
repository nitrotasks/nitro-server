assert = require "assert"
Auth = require "../app/auth"

describe "Auth ->", ->

  it "Register user", (done) ->
    Auth.register("stayradiated", "george@czabania.com", "password")
      .fail( -> console.log "error" )
      .then (user) ->
        assert.equal "stayradiated", user.username
        assert.equal "george@czabania.com", user.email
        done()
