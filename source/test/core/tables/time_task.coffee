should  = require('should')
setup   = require('../../setup')
db      = require('../../../core/controllers/database')

describe 'Database', ->

  before (done) ->
    setup()
    .then(setup.createUser)
    .then(setup.createList)
    .then(setup.createTask)
    .then(setup.createTimeTask)
    .then -> done()
    .done()

  beforeEach (done) ->
    db.time_task.destroy(setup.taskId)
    .then(setup.createTimeTask)
    .then -> done()
    .done()

  describe ':time_task', ->

    describe ':create', ->

      beforeEach (done) ->
        db.time_task.destroy(setup.taskId)
        .then -> done()
        .done()

      it 'should add timestamps to an existing task', (done) ->

        db.time_task.create(setup._timeTask)
        .then -> done()
        .done()

    describe ':read', ->

      it 'should read timestamps for an existing task', (done) ->

        db.time_task.read(setup.taskId)
        .then (times) ->
          times.should.eql
            id: setup.taskId
            listId: 1
            name: 1
            notes: 1
            priority: 1
            date: 1
            completed: 1
        .then -> done()
        .done()

    describe ':update', ->

      it 'should update timestamps for an existing task', (done) ->

        db.time_task.update setup.taskId,
          listId: 3
          name: 3
        .then ->
          db.time_task.read(setup.taskId, ['listId', 'name'])
        .then (times) ->
          times.listId.should.equal(3)
          times.name.should.equal(3)
        .then -> done()
        .done()

    describe ':destroy', ->

      it 'should destroy timestamps for an existing task', (done) ->

        db.time_task.destroy(setup.taskId)
        .then ->
          db.time_task.read(setup.taskId)
        .catch (err) ->
          err.message.should.equal('err_no_row')
          done()
        .done()
