should  = require 'should'
Promise = require 'bluebird'
setup   = require '../setup'
Sync    = require '../../core/controllers/sync'
Users   = require '../../core/models/user'
Time    = require '../../core/models/time'

describe 'Sync', ->

  user = null
  sync = null

  before (done) ->
    setup()
    .then(setup.createUser)
    .then(setup.createList)
    .then(setup.createTask)
    .then -> done()
    .done()

  beforeEach (done) ->
    Users.get(setup.userId)
    .then (_user) ->
      user = _user
      sync = new Sync(user)
    .then -> done()
    .done()

  describe ':task_create', ->

    it 'should create a task', (done) ->

      data =
        listId: setup.listId
        name: 'sync_task_name'

      sync.task_create(data)
      .then (id) ->
        user.tasks.get(id).call('read')
      .then (task) ->
        task.id.should.be.a.Number.and.greaterThan(setup.taskId)
        task.userId.should.equal(setup.userId)
        task.listId.should.equal(setup.listId)
        task.name.should.equal('sync_task_name')
      .then -> done()
      .done()

  describe ':list_create', ->

    it 'should create a list', (done) ->

      data =
        name: 'sync_list_name'

      sync.list_create(data)
      .then (id) ->
        user.lists.get(id).call('read')
      .then (list) ->
        list.id.should.be.a.Number.and.greaterThan(setup.listId)
        list.userId.should.equal(setup.userId)
        list.name.should.equal('sync_list_name')
      .then -> done()
      .done()


  describe ':task_update', ->

    taskId = null

    beforeEach (done) ->
      sync.task_create(listId: setup.listId)
      .then (id) ->
        taskId = id
      .then -> done()
      .done()

    it 'should update a task', (done) ->

      data =
        name: 'sync_task_name_updated'

      sync.task_update(taskId, data)
      .then (task) ->
        task.should.eql(data)
        user.tasks.get(taskId).call('read')
      .then (task) ->
        task.name.should.equal('sync_task_name_updated')
      .then -> done()
      .done()

  describe ':list_update', ->

    listId = null

    beforeEach (done) ->
      sync.list_create(name: 'sync_list_update')
      .then (id) ->
        listId = id
      .then -> done()
      .done()

    it 'should update a list', (done) ->

      data =
        name: 'sync_list_name_updated'

      sync.list_update(listId, data)
      .then (list) ->
        list.should.eql(data)
        user.lists.get(listId).call('read')
      .then (list) ->
        list.name.should.equal('sync_list_name_updated')
      .then -> done()
      .done()

  describe ':pref_update', ->

    it 'should update a pref', (done) ->

      data =
        sort: 1

      sync.pref_update(data)
      .then (pref) ->
        pref.should.eql(data)
        user.prefs.get(setup.userId).call('read')
      .then (pref) ->
        pref.sort.should.equal(1)
      .then -> done()
      .done()


  return

  lists = []
  tasks = []

  compareArray = (a, b) ->
    a.sort().should.eql b.sort()

  describe '#basic', ->

    it 'should add lists and tasks', (done) ->

      # Create three lists
      promise = Promise.all [
        sync.list_create name: 'List 1'
        sync.list_create name: 'List 2'
        sync.list_create name: 'List 3'
      ]

      promise.then (_lists) ->

        # Save list ids
        lists = _lists

        # Check lists exist
        Promise.all [
          user.readList lists[0]
          user.readList lists[1]
          user.readList lists[2]
        ]

      .then (_lists) ->

        _lists.should.eql [
          { name: 'List 1', id: lists[0] }
          { name: 'List 2', id: lists[1] }
          { name: 'List 3', id: lists[2] }
        ]

        # Create three tasks
        Promise.all [
          sync.task_create name: 'Task 1', listId: lists[0]
          sync.task_create name: 'Task 2', listId: lists[0]
          sync.task_create name: 'Task 3', listId: lists[0]
        ]

      .then (_tasks) ->

        # Save task ids
        tasks = _tasks

        # Check tasks exists
        Promise.all [
          user.readTask tasks[0]
          user.readTask tasks[1]
          user.readTask tasks[2]
        ]

      .then (_tasks) ->

        _tasks.should.eql [{
          name: 'Task 1', listId: lists[0], id: tasks[0],
          notes: null, priority: null, completed: null, date: null
        }, {
          name: 'Task 2', listId: lists[0], id: tasks[1],
          notes: null, priority: null, completed: null, date: null
        }, {
          name: 'Task 3', listId: lists[0], id: tasks[2],
          notes: null, priority: null, completed: null, date: null
        }]

        # Should add tasks to lists
        user.readListTasks lists[0]

      .then (_tasks) ->
        _tasks.length.should.equal tasks.length
        # TODO: TEST FOR SAME PROPERTIES
        done()

      .done()


    it 'should handle task and list updates', (done) ->

      # Update task names
      promise = Promise.all [
        sync.task_update id: tasks[0], name: 'Task 1 has been renamed'
        sync.task_update id: tasks[1], name: 'Task 2 has been renamed'
        sync.task_update id: tasks[2], name: 'Task 3 has been renamed'
      ]

      promise.then ->

        Promise.all [
          user.readTask tasks[0]
          user.readTask tasks[1]
          user.readTask tasks[2]
        ]

      .then (_tasks) ->

        # Check names have been updated
        _tasks[0].name.should.equal 'Task 1 has been renamed'
        _tasks[1].name.should.equal 'Task 2 has been renamed'
        _tasks[2].name.should.equal 'Task 3 has been renamed'

        # Update list names
        Promise.all [
          sync.list_update id: lists[0], name: 'List 1 has been renamed'
          sync.list_update id: lists[1], name: 'List 2 has been renamed'
          sync.list_update id: lists[2], name: 'List 3 has been renamed'
        ]

      .then ->

        Promise.all [
          user.readList lists[0]
          user.readList lists[1]
          user.readList lists[2]
        ]

      .then (_lists) ->

        # Check names have been updated
        _lists[0].name.should.equal 'List 1 has been renamed'
        _lists[1].name.should.equal 'List 2 has been renamed'
        _lists[2].name.should.equal 'List 3 has been renamed'

        # Update pref
        sync.pref_update
          sort: 1
          language: 'en-US'

      .then ->

        user.exportPref()

      .then (_prefs) ->

        _prefs.sort.should.equal 1
        _prefs.language.should.equal 'en-US'

        done()

      .done()


    it 'should move a task to another list', (done) ->

      promise = Promise.all [
        user.readTask tasks[0]
        user.readListTasks lists[0]
        user.readListTasks lists[1]
      ]

      promise.then ([task_0, list_0_tasks, list_1_tasks]) ->

        task_0.listId.should.equal lists[0]
        compareArray list_0_tasks, tasks
        list_1_tasks.should.eql []

        # Move task
        sync.task_update
          id: tasks[0]
          listId: lists[1]

      .then ->

        Promise.all [
          user.readTask tasks[0]
          user.readListTasks lists[0]
          user.readListTasks lists[1]
        ]

      .then ([task_0, list_0_tasks, list_1_tasks]) ->

        # Check task has been moved
        task_0.listId.should.equal lists[1]
        compareArray list_0_tasks, [tasks[1], tasks[2]]
        compareArray list_1_tasks, [tasks[0]]

        done()

      .done()


  describe '#timestamps', ->

    past = null

    before ->
      # Travel 10 seconds back in time!
      past = time.now() - 10

    it 'should respect timestamps - task', (done) ->

      sync.task_update({
        id: tasks[0], name: 'Task 1 in the past'
      }, {
        name: past
      }).catch (err) ->
        err.should.equal 'err_old_event'
        done()

    it 'should respect timestamps - list', (done) ->

      sync.list_update({
        id: lists[1], name: 'List 2 in the past'
      },{
        name: past
      }).catch (err) ->
        err.should.equal 'err_old_event'
        done()

    it 'should respect timestamps - pref', (done) ->

      sync.pref_update({
        sort: false
      }, {
        sort: past
      }).catch (err) ->
        err.should.equal 'err_old_event'
        done()


  describe '#non-existant-models', ->

    it 'should throw err when updating a non-existant task', (done) ->

      promise = sync.task_update
        id: tasks[2] + 10
        name: 'Task 4'

      promise.catch (err) ->
        err.should.equal 'err_no_row'
        done()

    it 'should throw err when updating a non-existant list', (done) ->

      promise = sync.list_update
        id: lists[2] + 10
        name: 'List 4'

      promise.catch (err) ->
        err.should.equal 'err_no_row'
        done()


  describe '#destroying-models', ->

    it 'should handle task and list destruction', (done) ->

      user.readListTasks(lists[1])
      .then (tasks) ->

        # Check that task is in the list
        tasks.should.eql [ tasks[0] ]

        sync.task_destroy tasks[0]

      .then ->

        # Check that the task has been deleted
        user.readTask tasks[0]

      .catch (err) ->

        err.should.equal 'err_no_row'
        user.readListTasks lists[1]

      .then (tasks) ->

        tasks.should.eql []

        # Destroy two lists
        Promise.all [
          sync.list_destroy lists[1]
          sync.list_destroy lists[2]
        ]

      .then ->

        # Check that the lists have been deleted
        user.readList lists[1]
      .catch (err) ->
        err.should.equal 'err_no_row'
        user.readList lists[2]
      .catch (err) ->
        err.should.equal 'err_no_row'

        # Destroy the last list that still has tasks in it
        sync.list_destroy lists[0]

      .then ->

        # Check that everything has been deleted
        user.readList lists[0]
      .catch (err) ->
        err.should.equal 'err_no_row'
        user.readTask tasks[1]
      .catch (err) ->
        err.should.equal 'err_no_row'
        user.readTask tasks[2]
      .catch (err) ->
        err.should.equal 'err_no_row'

        done()

      .done()


    it 'should throw err when destroying a non-existant task', (done) ->

      sync.task_destroy(tasks[2] + 10).catch (err) ->
        err.should.equal 'err_no_row'
        done()

    it 'should throw err when destroying a non-existant list', (done) ->

      sync.list_destroy(lists[2] + 10).catch (err) ->
        err.should.equal 'err_no_row'
        done()
