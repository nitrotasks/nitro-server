
# Testing the database storage engine

DB = require '../app/database'
connect = require '../app/connect'
assert = require 'assert'

describe 'Database', ->

  before (done) ->
    connect.init('testing')
    DB.connected
      .then ->
        DB.truncate 'users'
      .then ->
        done()
      .fail (err) ->
        console.log err

  user =
    name: 'George Czabania'
    email: 'george@czabania.com'
    password: 'password'
    pro: 1
    data_Task: {
      name: 'nitro sync'
    }
    data_List: {
      hello: 'world'
    }
    data_Time: {
      some: 'timestamps'
    }
    data_Setting: {
      moar: 'stuff'
    }
    index_Task: 2
    index_List: 100
    created_at: new Date()

  it 'should add a user', (done) ->

    DB.user.write(user).then (_uid) ->
      user.id = _uid
      done()

  it 'should read the data back', (done) ->
    DB.user.read(user.id).then (user) ->
      for k, v of user
        if v instanceof Date
          assert.equal(v.toString(), user[k].toString())
        else if typeof v is 'object'
          assert.deepEqual(v, user[k])
        else
          assert.equal(v, user[k])
      done()

  it 'should delete the user data', (done) ->
    DB.user.delete(user.id).then -> done()

  it 'should close the connection to the server', ->
    DB.close()

