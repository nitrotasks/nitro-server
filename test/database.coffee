
# Testing the database storage engine

DB = require '../app/database.coffee'
assert = require 'assert'

describe 'Database', ->

  uid = 0

  it 'should connect to the server', ->
    DB.connect()

  it 'should add a user', (done) ->

    user =
      name: 'George Czabania'
      email: 'george@czabania.com'
      password: 'password'
      pro: 1
      tasks: {
        name: "Jonny"
      }

    DB.user.write(user).then (_uid) ->
      uid = _uid
      done()

  it 'should read the data back', (done) ->

    DB.user.read(uid).then (user) ->
      console.log 'user', user
      done()

  it 'should delete the user data', (done) ->
    DB.user.delete(uid).then -> done()
