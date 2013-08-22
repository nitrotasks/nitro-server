
# Testing the database storage engine

DB = require '../app/database.coffee'
assert = require 'assert'

describe 'Database', ->

  USER =
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

  it 'should connect to the server', (done) ->
    DB.connect().then ->
      done()

  it 'should add a user', (done) ->

    DB.user.write(USER)
      .then (_uid) ->
        USER.id = _uid
        done()
      .fail (err) ->
        throw err

  it 'should read the data back', (done) ->
    DB.user.read(USER.id).then (user) ->
      for k, v of USER
        if v instanceof Date
          assert.equal(v.toString(), user[k].toString())
        else if typeof v is 'object'
          assert.deepEqual(v, user[k])
        else
          assert.equal(v, user[k])
      done()

  it 'should delete the user data', (done) ->
    DB.user.delete(USER.id).then -> done()

  it 'should close the connection to the server', ->
    DB.close()
    
