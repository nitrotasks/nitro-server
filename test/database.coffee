should = require 'should'
database = require '../app/controllers/query'

setup   = require './setup'
should  = require 'should'

# Testing the database storage engine

describe 'Database', ->

  user = {}

  before setup

  describe '#setup', ->

    it 'should have access to lists, tasks, etc.', ->
      database.task.should.be.ok
      database.user.should.be.ok
      database.util.should.be.ok


  describe '#user', ->

    it 'should create a new user', (done) ->

      model =
        name: 'Jimmy'
        email: 'jimmy@gmail.com'
        password: 'blah'
        pro: 0

      database.user.create(model).then (id) ->
        user.id = id
        done()


    it 'should fetch a users information', (done) ->

      database.user.read(user.id).then (info) ->
        info.id.should.equal user.id
        done()


    it 'should update an existing user', (done) ->

      model =
        name: 'James'

      database.user.update(model).then -> done()


  describe '#task', ->

    it 'should create a new task', (done) ->

      model =
        user_id: user.id
        name: 'Task 1'

      database.task.create(model)
        .then -> done()
        .fail (err) -> console.log err


