should  = require('should')
setup   = require('../../setup')
db      = require('../../../core/controllers/database')

describe 'Database', ->

  before (done) ->
    setup()
    .then(setup.createUser)
    .then(setup.createList)
    .then -> done()
    .done()

  describe '#task_and_lists', ->

    it 'should require tasks to have a list', (done) ->

      model =
        userId: setup.userId
        listId: 2000
        name: 'tasks_and_lists'

      db.task.create(model)
      .catch (err) ->
        err.message.should.equal('err_could_not_create_row')
        done()
      .done()

    it 'deleting a task should remove it from a list', (done) ->

      task =
        userId: setup.userId
        listId: setup.listId
        name: 'tasks_and_lists'

      # Create a new task
      db.task.create(task)
      .then (id) ->
        task.id = id

        # Add the task to the list
        db.list_tasks.create(setup.listId, task.id)

      .then ->

        # Check that we have added the task
        db.list_tasks.read(setup.listId)
      .then (tasks) ->
        tasks.should.eql [ task.id ]

        # Destroy the task
        db.task.destroy(task.id)

      .then ->

        # Check that the task is no longer in the list
        db.list_tasks.read(setup.listId)

      .then (tasks) ->
        tasks.should.eql []

      .then -> done()
      .done()
