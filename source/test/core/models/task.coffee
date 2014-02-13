require('should')
setup = require('../../setup')
Task  = require('../../../core/models/task')

describe 'Task', ->

  before (done) ->
    setup()
    .then(setup.createUser)
    .then(setup.createList)
    .then(setup.createTask)
    .return()
    .then(done)

  describe ':create', ->

  describe ':get', ->

  describe ':owns', ->

  describe ':all', ->

    it 'should get all users tasks', (done) ->

      task = new Task(1)
      task.all().then (tasks) ->
        tasks.should.eql [
          id: 1
          userId: 1
          listId: 1
          name: 'task_name'
          notes: 'task_notes'
          date: 0
          priority: 0
          completed: 0
        ]
      .return().then(done).done()

  describe ':destroy', ->