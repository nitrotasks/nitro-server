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
    db.task.destroy(setup.taskId)
    .then(setup.createTask)
    .then -> done()
    .done()

  describe ':task', ->

    describe ':create', ->

      beforeEach (done) ->
        db.task.destroy(setup.taskId)
        .then -> done()
        .done()

      it 'should create a new task', (done) ->

        db.task.create
          userId: setup.userId
          listId: setup.listId
          name: 'this is my list'
        .then (id) ->
          id.should.be.a.Number
        .then -> done()
        .done()

    describe ':read', ->

      it 'should read an existing task', (done) ->

        db.task.read(setup.taskId)
        .then (task) ->
          task.should.eql
            id: setup.taskId
            userId: setup.userId
            listId: setup.listId
            name: 'task_name'
            notes: 'task_notes'
            date: 0
            completed: 0
            priority: 0
        .then -> done()
        .done()

    describe ':update', ->

      it 'should update an existing task', (done) ->

        db.task.update setup.taskId,
          name: 'task_name_updated'
        .then ->
          db.task.read(setup.taskId, 'name')
        .then (task) ->
          task.name.should.equal('task_name_updated')
        .then -> done()
        .done()

    describe ':destroy', ->

      it 'should destroy an existing task', (done) ->

        db.task.destroy(setup.taskId)
        .then ->
          db.task.read(setup.taskId)
        .catch (err) ->
          err.message.should.equal('err_no_row')
          done()
        .done()

