require('should')
setup = require('../../setup')
Tasks = require('../../../core/models/task')
Lists = require('../../../core/models/list')

describe 'Task', ->

  tasks = null

  before (done) ->
    setup()
    .then(setup.createUser)
    .then(setup.createList)
    .then -> done()
    .done()

  beforeEach (done) ->
    tasks = new Tasks(setup.userId)
    tasks.destroy()
    .then(setup.createTask)
    .then -> done()
    .done()

  describe ':create', ->

    it 'should create a task', (done) ->

      id = null

      tasks.create
        listId: setup.listId
        name: 'test_name'
        notes: 'test_notes'
        date: 27
        priority: 2
        completed: 42
      .then (_id) ->
        id = _id
        id.should.be.a.Number
        tasks.get(id).call('read')
      .then (task) ->
        task.should.eql
          id: id
          userId: setup.userId
          listId: setup.listId
          name: 'test_name'
          notes: 'test_notes'
          date: 27
          priority: 2
          completed: 42
      .then -> done()
      .done()

    it 'should not throw err when column does not exist', (done) ->

      id = null

      tasks.create
        listId: setup.listId
        foo: 'bar'
      .then (_id) ->
        id = _id
        id.should.be.a.Number
        tasks.get(id).call('read')
      .then (task) ->
        task.should.eql
          id: id
          userId: setup.userId
          listId: setup.listId
          name: null
          notes: null
          date: null
          priority: null
          completed: null
      .then -> done()
      .done()

  describe ':get', ->

    it 'should get a task', (done) ->

      tasks.get(setup.taskId)
      .then (task) ->
        task.should.be.an.instanceOf(Tasks.Task)
        task.id.should.equal(setup.taskId)
      .then -> done()
      .done()

    it 'should throw err if task does not exist', (done) ->

      tasks.get(-1)
      .catch (err) ->
        err.message.should.equal('err_no_row')
        done()
      .done()

  describe ':owns', ->

    it 'should own a task', (done) ->

      tasks.owns(setup.taskId)
      .then (success) ->
        success.should.equal(true)
      .then -> done()
      .done()

    it 'should throw err when task does not exist', (done) ->

      tasks.owns(-1)
      .catch (err) ->
        err.message.should.equal('err_no_row')
        done()
      .done()

    it 'should throw err when user does not own task', (done) ->

      setup.createUser('_custom')
      .then(setup.createList)
      .then(setup.createTask)
      .then (id) ->
        tasks.owns(id)
      .catch (err) ->
        err.message.should.equal('err_no_row')
        done()
      .done()

  describe ':all', ->

    it 'should get all users tasks', (done) ->

      tasks.all().then (tasks) ->
        tasks.should.eql [
          id: setup.taskId
          userId: setup.userId
          listId: setup.listId
          name: 'task_name'
          notes: 'task_notes'
          date: 0
          priority: 0
          completed: 0
        ]
      .then -> done()
      .done()

    it 'should not throw err if user does not have any tasks', (done) ->

      tasks.destroy()
      .bind(tasks)
      .then(tasks.all)
      .then (tasks) ->
        tasks.should.eql []
      .then -> done()
      .done()

  describe ':destroy', ->

    it 'should destroy all tasks owned by a user', (done) ->

      tasks.destroy()
      .bind(tasks)
      .then(tasks.all)
      .then (tasks) ->
        tasks.should.eql []
      .then -> done()
      .done()

    it 'should not throw err if user does not have any tasks', (done) ->

      tasks.destroy()
      .bind(tasks)
      .then(tasks.destroy)
      .then(tasks.all)
      .then (tasks) ->
        tasks.should.eql []
      .then -> done()
      .done()

  describe ':Task', ->

    task = null

    beforeEach (done) ->
      tasks.get(setup.taskId)
      .then (_task) ->
        task = _task
      .then -> done()
      .done()


    describe ':read', ->

      it 'should read a single column', (done) ->

        task.read('name')
        .then (data) ->
          data.should.eql
            name: 'task_name'
        .then -> done()
        .done()

      it 'should read multiple columns', (done) ->

        task.read(['name', 'notes'])
        .then (data) ->
          data.should.eql
            name: 'task_name'
            notes: 'task_notes'
        .then -> done()
        .done()

      it 'should read all the columns', (done) ->

        task.read()
        .then (data) ->
          data.should.eql
            id: setup.taskId
            userId: setup.userId
            listId: setup.listId
            name: 'task_name'
            notes: 'task_notes'
            date: 0
            priority: 0
            completed: 0
        .then -> done()
        .done()

      it 'should throw err when task does not exist', (done) ->

        task = new Tasks.Task(-1)
        task.read()
        .catch (err) ->
          err.message.should.equal('err_no_row')
          done()
        .done()

    describe ':update', ->

      it 'should update a single column', (done) ->

        task.update(name: 'task_name_updated')
        .then ->
          task.read('name')
        .then (data) ->
          data.should.eql
            name: 'task_name_updated'
        .then -> done()
        .done()

      it 'should update multiple columns', (done) ->

        task.update
          date: 32
          priority: 10
        .then ->
          task.read(['date', 'priority'])
        .then (data) ->
          data.should.eql
            date: 32
            priority: 10
        .then -> done()
        .done()

      it 'should throw err when task does not exist', (done) ->

        task = new Tasks.Task(-1)
        task.update(name: 'task_name_updated')
        .catch (err) ->
          err.message.should.equal('err_no_row')
          done()
        .done()

      it 'should throw err when column does not exist', (done) ->

        task.update(fake: 'err')
        .catch (err) ->
          err.message.should.eql('err_could_not_update_row')
          done()
        .done()

    describe ':destroy', ->

      it 'should destroy a task', (done) ->

        task.destroy()
        .then ->
          task.read()
        .catch (err) ->
          err.message.should.eql 'err_no_row'
          done()
        .done()

      it 'should throw err when the task does not exist', (done) ->

        task = new Tasks.Task(-1)
        task.destroy()
        .catch (err) ->
          err.message.should.equal 'err_no_row'
          done()
        .done()

    describe 'List', ->

      list = null

      beforeEach ->
        list = new Lists.List(setup.listId)

      describe ':addToList', ->

        it 'should add a task to a list', (done) ->

          task.removeFromList(list.id)
          .then ->
            task.addToList(list.id)
          .then ->
            list.tasks()
          .then (tasks) ->
            tasks.should.eql [ setup.taskId ]
          .then -> done()
          .done()

        it 'should throw err when task does not exist', (done) ->

          task = new Tasks.Task(-1)
          task.addToList(list.id)
          .catch (err) ->
            err.message.should.equal('err_could_not_create_row')
            done()
          .done()

        it 'should throw err when list does not exist', (done) ->

          list = new Lists.List(-1)
          task.addToList(list.id)
          .catch (err) ->
            err.message.should.equal('err_could_not_create_row')
            done()
          .done()

        it 'should throw err when task is already in list', (done) ->

          task.addToList(list.id)
          .catch (err) ->
            err.message.should.equal('err_could_not_create_row')
            done()
          .done()

      describe ':removeFromList', ->

        it 'should remove a task from a list', (done) ->

          list.tasks()
          .then (tasks) ->
            tasks.should.eql [ setup.taskId ]
            task.removeFromList(list.id)
          .then ->
            list.tasks()
          .then (tasks) ->
            tasks.should.eql []
          .then -> done()
          .done()

        it 'should throw err when task does not exist', (done) ->

          task = new Tasks.Task(-1)
          task.removeFromList(list.id)
          .catch (err) ->
            err.message.should.equal('err_no_row')
            done()
          .done()

        it 'should throw err when list does not exist', (done) ->

          list = new Lists.List(-1)
          task.removeFromList(list.id)
          .catch (err) ->
            err.message.should.equal('err_no_row')
            done()
          .done()

        it 'should throw err when task is already in list', (done) ->

          task.removeFromList(list.id)
          .then ->
            task.removeFromList(list.id)
          .catch (err) ->
            err.message.should.equal('err_no_row')
            done()
          .done()
