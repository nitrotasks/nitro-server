should  = require('should')
setup   = require('../../setup')
db      = require('../../../core/controllers/database')

describe 'Database', ->

  before (done) ->
    setup()
    .then(setup.createUser)
    .then(setup.createList)
    .then(setup.createTask)
    .then -> done()
    .done()

  beforeEach (done) ->
    db.list.destroy(setup.listId)
    .then(setup.createList)
    .then(setup.createTask)
    .then -> done()
    .done()

  describe ':list_tasks', ->

    describe ':create', ->

      beforeEach (done) ->
        db.list_tasks.destroyAll(setup.listId)
        .then -> done()
        .done()

      it 'should add a task to a list', (done) ->

        db.list_tasks.create(setup.listId, setup.taskId)
        .then -> done()
        .done()

      it 'should throw err when adding a task twice', (done) ->

        db.list_tasks.create(setup.listId, setup.taskId)
        .then ->
          db.list_tasks.create(setup.listId, setup.taskId)
        .catch (err) ->
          err.message.should.equal('err_could_not_create_row')
          done()
        .done()

      it 'should throw err when task does not exist', (done) ->

        db.list.destroy(setup.listId)
        .then ->
          db.list_tasks.create(setup.listId, setup.taskId)
        .catch (err) ->
          err.message.should.equal('err_could_not_create_row')
          done()
        .done()

      it 'should throw err when list does not exist', (done) ->

        db.task.destroy(setup.taskId)
        .then ->
          db.list_tasks.create(setup.listId, setup.taskId)
        .catch (err) ->
          err.message.should.equal('err_could_not_create_row')
          done()
        .done()

    describe ':read', ->

      it 'should read all tasks from a list', (done) ->

        db.list_tasks.read(setup.listId)
        .then (tasks) ->
          tasks.should.eql [ setup.taskId ]
        .then -> done()
        .done()

      it 'should return an empty array when there are no tasks', (done) ->

        db.list_tasks.destroyAll(setup.listId)
        .then ->
          db.list_tasks.read(setup.listId)
        .then (tasks) ->
          tasks.should.eql []
        .then -> done()
        .done()

    describe ':update', ->

      it 'should move a task to another list', (done) ->

        oldList = setup.listId

        setup.createList()
        .then ->
          db.list_tasks.update setup.taskId, setup.listId
        .then ->
          db.list_tasks.read(oldList)
        .then (tasks) ->
          tasks.should.eql []
          db.list_tasks.read(setup.listId)
        .then (tasks) ->
          tasks.should.eql [ setup.taskId ]
        .then -> done()
        .done()

      it 'should not fail if list does not change', (done) ->

        db.list_tasks.update setup.taskId, setup.listId
        .then ->
          db.list_tasks.read(setup.listId)
        .then (tasks) ->
          tasks.should.eql [ setup.taskId ]
        .then -> done()
        .done()

    describe ':destroy', ->

      it 'should remove a task from a list', (done) ->

        db.list_tasks.destroy(setup.listId, setup.taskId)
        .then ->
          db.list_tasks.read(setup.listId)
        .then (tasks) ->
          tasks.should.eql []
        .then -> done()
        .done()

      it 'should remove all tasks from a list', (done) ->

        db.list_tasks.destroyAll(setup.listId)
        .then ->
          db.list_tasks.read(setup.listId)
        .then (tasks) ->
          tasks.should.eql []
          done()
