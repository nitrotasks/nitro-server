app = require "../app"
request = require "supertest"
assert = require "assert"

# Put the app into debug mode
# This returns tokens via HTTP rather than emailing them
app.__debug()

global = {}

describe 'Auth API', ->

  # Registration

  it "should be able to register a user", (done) ->
    request(app)
      .post("/api/register")
      .send( name: "George", email: "example@email.com", password: "password" )
      .end (err, res) ->
        assert.equal res.body[1].length, 64
        # Save token for later tests
        global.token = res.body[1]
        done()

  it "will allow users to register with a duplicate email address", (done) ->
    request(app)
      .post("/api/register")
      .send( name: "Jono", email: "example@email.com", password: "password" )
      .end (err, res) ->
        assert.equal res.body[1].length, 64
        global.oldToken = res.body[1]
        done()

  it "should verify the users token and add the user", (done) ->
    request(app)
      .get("/api/register/#{global.token}")
      .expect("success", done )

  it "won't let users register with a verified email address already in use", (done) ->
    request(app)
      .post("/api/register")
      .send( name: "Jono", email: "example@email.com", password: "password" )
      .expect("err_old_email", done )

  it "won't allow users to use a token for an old email address", (done) ->
    # Example: A user signs up twice with the same email adrress
    # They will get two tokens. When they sign up with one, the other one
    # should no longer work
    request(app)
      .get("/api/register/#{global.oldToken}")
      .expect("err_old_email", done)

  it "won't allow users to use a token that doesn't exist", (done) ->
    # Example: The token has been used or expired or never existed
    request(app)
      .get("/api/register/#{global.token}")
      .expect("err_bad_token", done)


  # Validation

  it "should require users to have a name", (done) ->
    request(app)
      .post("/api/register")
      .send( name: "", email: "example@email.com", password: "password")
      .expect( "err_bad_name", done )

  it "should require users to have a valid email", (done) ->
    request(app)
      .post("/api/register")
      .send( name: "George", email: "", password: "password")
      .expect( "err_bad_email", done )

  it "should require users to have a password", (done) ->
    request(app)
      .post("/api/register")
      .send( name: "George", email: "example@email.com", password: "")
      .expect( "err_bad_pass", done )


  # Logging in

  it "should allow users to login", (done) ->
    request(app)
      .post("/api/login")
      .send( email: "example@email.com", password: "password" )
      .end (err, res) ->
        [id, token, email, name] = res.body
        assert.equal token.length, 64
        assert.equal email, "example@email.com"
        assert.equal name, "George"
        done()

  it "should not allow users to login with the incorrect password", (done) ->
    request(app)
      .post("/api/login")
      .send( email: "example@email.com", password: "hunter2" )
      .expect( "err_bad_pass", done )

  it "should not allow users to login with a non-existant email", (done) ->
    request(app)
      .post("/api/login")
      .send( email: "random@thing.net", password: "password" )
      .expect( "err_bad_pass", done )

  it "should allow users to reset their password", (done) ->
    request(app)
      .post("/api/auth/forgot/")
      .send( email: "example@email.com" )
      .end (err, res) ->
        assert.notEqual res.text, "err_bad_email"
        global.token = res.text
        done()

  it "should fail if the email address doesn't exist", (done) ->
    request(app)
      .post("/api/auth/forgot/")
      .send( email: "not.an@email.com" )
      .expect( "err_bad_email", done )

  it "should allow the user to use a token", (done) ->
    request(app)
      .get("/api/auth/forgot/#{global.token}")
      .end (err, res) ->
        done()

  it "should fail if the token doesn't exist", (done) ->
    request(app)
      .get("/api/auth/forgot/somesillytoken")
      .expect( "err_bad_token", done )
