should = require 'should'
database = require '../app/controllers/query'

setup   = require './setup'
should  = require 'should'

# Testing the database storage engine

describe 'Database', ->

  user =
    name: 'Jimmy'
    email: 'jimmy@gmail.com'
    password: 'blah'
    pro: 0

  before setup

  describe '#setup', ->

    it 'should have access to lists, tasks, etc.', ->
      database.task.should.be.ok
      database.user.should.be.ok
      database.util.should.be.ok


  describe '#user', ->

    it 'should create a new user', (done) ->

      database.user.create(user).then (id) ->
        user.id = id
        done()

    it 'should fetch a users information', (done) ->

      database.user.read(user.id).then (info) ->
        info.id.should.equal user.id
        done()

    it 'should update an existing user', (done) ->

      model = name: 'James'
      database.user.update(user.id, model).then -> done()

    it 'should delete an existing user', (done) ->

      database.user.destroy(user.id).then -> done()

    it 'should fail when fetching a user that does not exist', (done) ->

      database.user.read(user.id).fail -> done()

    it 'should fail when updating a user that does not exist', (done) ->

      model = email: 'james@gmail.com'
      database.user.update(user.id, model).fail -> done()

    it 'should fail when destroying a user that does not exist', (done) ->

      database.user.destroy(user.id).fail -> done()


  describe '#task', ->

    before (done) ->
      database.user.create(user).then (id) ->
        user.id = id
        done()

    it 'should create a new task', (done) ->

      model =
        user_id: user.id
        name: 'Task 1'

      database.task.create(model).then (id) ->
        done()


