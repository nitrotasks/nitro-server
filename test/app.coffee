app = require "../app"
request = require "supertest"
assert = require "assert"

global = {}

describe 'Auth API', ->


  # Registration

  it "should be able to register a user", (done) ->
    request(app)
      .post("/api/v0/auth/register")
      .send( name: "George", email: "example@email.com", password: "password" )
      .end (err, res) ->
        # Should return an array in the format [<id>, <token>]
        assert.equal res.body[1].length, 64
        done()

  it "should fail if the user tries to register with an existing email address", (done) ->
    request(app)
      .post("/api/v0/auth/register")
      .send( name: "Jono", email: "example@email.com", password: "password" )
      .expect( "err_old_email", done )


  # Validation

  it "should require users to have a name", (done) ->
    request(app)
      .post("/api/v0/auth/register")
      .send( name: "", email: "example@email.com", password: "password")
      .expect( "err_bad_name", done )

  it "should require users to have a valid email", (done) ->
    request(app)
      .post("/api/v0/auth/register")
      .send( name: "George", email: "", password: "password")
      .expect( "err_bad_email", done )

  it "should require users to have a password", (done) ->
    request(app)
      .post("/api/v0/auth/register")
      .send( name: "George", email: "example@email.com", password: "")
      .expect( "err_bad_pass", done )


  # Logging in

  it "should allow users to login", (done) ->
    request(app)
      .post("/api/v0/auth/login")
      .send( email: "example@email.com", password: "password" )
      .end (err, res) ->
        # Should return an array in the format [<id>, <token>]
        assert.equal res.body[1].length, 64
        done()

  it "should not allow users to login with the incorrect password", (done) ->
    request(app)
      .post("/api/v0/auth/login")
      .send( email: "example@email.com", password: "hunter2" )
      .expect( "err_bad_pass", done )

  it "should not allow users to login with a non-existant email", (done) ->
    request(app)
      .post("/api/v0/auth/login")
      .send( email: "random@thing.net", password: "password" )
      .expect( "err_bad_pass", done )

  it "should allow users to reset their password", (done) ->
    request(app)
      .post("/api/v0/auth/forgot/")
      .send( email: "example@email.com" )
      .end (err, res) ->
        assert.notEqual res.text, "err_bad_email"
        global.token = res.text
        done()

  it "should fail if the email address doesn't exist", (done) ->
    request(app)
      .post("/api/v0/auth/forgot/")
      .send( email: "not.an@email.com" )
      .expect( "err_bad_email", done )

  it "should allow the user to use a token", (done) ->
    request(app)
      .get("/api/v0/auth/forgot/#{global.token}")
      .end (err, res) ->
        done()

  it "should fail if the token doesn't exist", (done) ->
    request(app)
      .get("/api/v0/auth/forgot/somesillytoken")
      .expect( "err_bad_token", done )
