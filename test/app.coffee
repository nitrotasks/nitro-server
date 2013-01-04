app = require "../app"
request = require "supertest"

describe 'Auth API', ->
  it "should be able to register a user", (done) ->
    request(app)
      .post("/api/v0/auth/register")
      .send( name: "George", email: "example@email.com", password: "password" )
      .expect( "true", done )

  it "should fail if the user tries to register with an existing email address", (done) ->
    request(app)
      .post("/api/v0/auth/register")
      .send( name: "Jono", email: "example@email.com", password: "password" )
      .expect( "err_bad_email", done )

  it "should allow users to login", (done) ->
    request(app)
      .post("/api/v0/auth/login")
      .send( email: "example@email.com", password: "password" )
      .expect( "true", done )

  it "should not allow users to login with the incorrect password", (done) ->
    request(app)
      .post("/api/v0/auth/login")
      .send( email: "example@email.com", password: "hunter2" )
      .expect( "err_bad_pass", done )

  it "should not allow users to login with a non-existant email", (done) ->
    request(app)
      .post("/api/v0/auth/login")
      .send( email: "random@thing.net", password: "password" )
      .expect( "err_bad_email", done )
