DB      = require '../app/controllers/database'
setup   = require './setup'
should  = require 'should'

# Testing the database storage engine

describe 'Database', ->

  before setup

  user =
    name: 'George Czabania'
    email: 'george@czabania.com'
    password: 'password'
    pro: 1
    data_task:
      name: 'nitro sync'
    data_list:
      hello: 'world'
    data_time:
      some: 'timestamps'
    data_pref:
      moar: 'stuff'
    index_task: 2
    index_list: 100
    created_at: new Date()

  it 'should add a user', (done) ->

    DB.user.write(user).then (_uid) ->
      user.id = _uid
      done()

  it 'should read the data back', (done) ->

    DB.user.read(user.id).then (user) ->
      for k, v of user
        if v instanceof Date
          v.should.eql user[k]
        else if typeof v is 'object'
          v.should.eql user[k]
        else
          v.should.eql user[k]
      done()

  it 'should delete the user data', (done) ->

    DB.user.delete(user.id).then -> done()
