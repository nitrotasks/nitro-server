should  = require('should')
Promise = require('bluebird')
setup   = require('../setup')
Sync    = require('../../core/controllers/sync')
Users   = require '../../core/models/user'
Lists   = require '../../core/models/list'
Tasks   = require '../../core/models/task'
Time    = require('../../core/models/time')

describe 'Sync API', ->

  user = null
  sync = null

  before (done) ->
    setup()
    .then(setup.createUser)
    .then -> done()
    .done()

  beforeEach (done) ->
    Users.get(setup.userId)
    .then (_user) ->
      user = _user
      sync = new Sync(user, 'test-sync-complex')
    .then -> done()
    .done()

  compareArray = (a, b) ->
    a.sort().should.eql b.sort()

  lists = []
  tasks = []

  describe '#basic', ->

    it 'should add lists and tasks', (done) ->

      # Create three lists
      Promise.all [
        sync.list.create name: 'List 1'
        sync.list.create name: 'List 2'
        sync.list.create name: 'List 3'
      ]

      .map (list) ->
        lists.push(list.id)
        new Lists.List(list.id)
      .map (list) ->
        list.read()
      .then (_lists) ->

        _lists.should.eql [
          { name: 'List 1', id: lists[0], userId: setup.userId}
          { name: 'List 2', id: lists[1], userId: setup.userId}
          { name: 'List 3', id: lists[2], userId: setup.userId}
        ]

        # Create three tasks
        Promise.all [
          sync.task.create name: 'Task 1', listId: lists[0]
          sync.task.create name: 'Task 2', listId: lists[0]
          sync.task.create name: 'Task 3', listId: lists[0]
        ]

      .map (task) ->
        tasks.push(task.id)
        new Tasks.Task(task.id)
      .map (task) ->
        task.read()
      .then (_tasks) ->

        _tasks.should.eql [{
          userId: setup.userId
          name: 'Task 1', listId: lists[0], id: tasks[0],
          notes: null, priority: null, completed: null, date: null
        }, {
          userId: setup.userId
          name: 'Task 2', listId: lists[0], id: tasks[1],
          notes: null, priority: null, completed: null, date: null
        }, {
          userId: setup.userId
          name: 'Task 3', listId: lists[0], id: tasks[2],
          notes: null, priority: null, completed: null, date: null
        }]

        # Should add tasks to lists
        user.list.get(lists[0]).call('tasks')

      .then (_tasks) ->

        compareArray(_tasks, tasks)

      .then -> done()
      .done()


    it 'should handle task and list updates', (done) ->

      # Update task names
      Promise.all [
        sync.task.update tasks[0], name: 'Task 1 has been renamed'
        sync.task.update tasks[1], name: 'Task 2 has been renamed'
        sync.task.update tasks[2], name: 'Task 3 has been renamed'
      ]

      .map (task) ->
        new Tasks.Task(task.id)
      .map (task) ->
        task.read()
      .then (_tasks) ->

        # Check names have been updated
        _tasks[0].name.should.equal 'Task 1 has been renamed'
        _tasks[1].name.should.equal 'Task 2 has been renamed'
        _tasks[2].name.should.equal 'Task 3 has been renamed'

        # Update list names
        Promise.all [
          sync.list.update lists[0], name: 'List 1 has been renamed'
          sync.list.update lists[1], name: 'List 2 has been renamed'
          sync.list.update lists[2], name: 'List 3 has been renamed'
        ]

      .map (list) ->
        new Lists.List(list.id)
      .map (list) ->
        list.read()

      .then (_lists) ->

        # Check names have been updated
        _lists[0].name.should.equal 'List 1 has been renamed'
        _lists[1].name.should.equal 'List 2 has been renamed'
        _lists[2].name.should.equal 'List 3 has been renamed'

        # Update pref
        sync.pref.update null,
          sort: 1
          language: 'en-US'

      .then ->
        user.pref.read()

      .then (_prefs) ->
        _prefs.sort.should.equal 1
        _prefs.language.should.equal 'en-US'

      .then -> done()
      .done()


    it 'should move a task to another list', (done) ->

      task = new Tasks.Task(tasks[0])
      list_0 = new Lists.List(lists[0])
      list_1 = new Lists.List(lists[1])

      Promise.all [
        task.read()
        list_0.tasks()
        list_1.tasks()
      ]

      .spread (task_0, list_0_tasks, list_1_tasks) ->

        task_0.listId.should.equal(lists[0])
        compareArray(list_0_tasks, tasks)
        list_1_tasks.should.eql([])

        # Move task
        sync.task.update tasks[0],
          listId: lists[1]

      .then ->

        Promise.all [
          task.read()
          list_0.tasks()
          list_1.tasks()
        ]

      .spread (task_0, list_0_tasks, list_1_tasks) ->

        # Check task has been moved
        task_0.listId.should.equal(lists[1])
        compareArray(list_0_tasks, [tasks[1], tasks[2]])
        compareArray(list_1_tasks, [tasks[0]])

      .then -> done()
      .done()


  describe '#timestamps', ->

    past = null

    before ->
      # Travel 10 seconds back in time!
      past = Time.now() - 10

    it 'should respect timestamps - task', (done) ->

      sync.task.update tasks[0],
        { name: 'Task 1 in the past' }
        { name: past }
      .catch (err) ->
        err.message.should.equal('err_old_time')
        done()
      .done()

    it 'should respect timestamps - list', (done) ->

      sync.list.update lists[1],
        { name: 'List 2 in the past' }
        { name: past }
      .catch (err) ->
        err.message.should.equal('err_old_time')
        done()
      .done()

    it 'should respect timestamps - pref', (done) ->

      sync.pref.update null, { sort: false }, { sort: past }
      .catch (err) ->
        err.message.should.equal('err_old_time')
        done()
      .done()


  describe '#non-existant-models', ->

    it 'should throw err when updating a non-existant task', (done) ->

      sync.task.update -1, name: 'Task 4'
      .catch (err) ->
        err.message.should.equal 'err_no_row'
        done()
      .done()

    it 'should throw err when updating a non-existant list', (done) ->

      sync.list.update -1, name: 'List 4'
      .catch (err) ->
        err.message.should.equal 'err_no_row'
        done()
      .done()


  describe '#destroying-models', ->

    it 'should handle task and list destruction', (done) ->

      task_0 = new Tasks.Task(tasks[0])
      task_1 = new Tasks.Task(tasks[1])
      task_2 = new Tasks.Task(tasks[2])
      list_0 = new Lists.List(lists[0])
      list_1 = new Lists.List(lists[1])
      list_2 = new Lists.List(lists[2])

      list_1.tasks()
      .then (tasks) ->

        # Check that task is in the list
        tasks.should.eql [ tasks[0] ]

        sync.task.destroy tasks[0]

      .then ->

        # Check that the task has been deleted
        task_0.read()

      .catch (err) ->

        err.message.should.equal 'err_no_row'
        list_1.tasks()

      .then (tasks) ->

        tasks.should.eql []

        # Destroy two lists
        Promise.all [
          sync.list.destroy lists[1]
          sync.list.destroy lists[2]
        ]

      .then ->

        # Check that the lists have been deleted

        list_1.read()
      .catch (err) ->
        err.message.should.equal 'err_no_row'

        list_2.read()
      .catch (err) ->
        err.message.should.equal 'err_no_row'

        # Destroy the last list that still has tasks in it
        sync.list.destroy(lists[0])

      .then ->

        # Check that everything has been deleted

        list_0.read()
      .catch (err) ->
        err.message.should.equal 'err_no_row'

        task_1.read()
      .catch (err) ->
        err.message.should.equal 'err_no_row'

        task_2.read()
      .catch (err) ->
        err.message.should.equal 'err_no_row'

        done()

      .done()


    it 'should throw err when destroying a non-existant task', (done) ->

      sync.task.destroy(-1)
      .catch (err) ->
        err.message.should.equal 'err_no_row'
        done()
      .done()

    it 'should throw err when destroying a non-existant list', (done) ->

      sync.list.destroy(-1)
      .catch (err) ->
        err.message.should.equal 'err_no_row'
        done()
      .done()
