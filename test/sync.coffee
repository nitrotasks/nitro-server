Sync   = require '../app/controllers/sync'
Auth   = require '../app/controllers/auth'
setup  = require './setup'
should = require 'should'
Q      = require 'kew'
Log = require '../app/utils/log'
time = require '../app/utils/time'

log = Log 'sync - test'

LIST = 'list'
TASK = 'task'
PREF = 'pref'


describe 'Sync API', ->

  user = null
  sync = null

  lists = []
  tasks = []

  compareArray = (a, b) ->
    a.sort().should.eql b.sort()

  before (done) -> setup ->
    Auth.register('George', 'mail@example.com', 'password')
    .then (token) ->
      Auth.verifyRegistration(token)
    .then (_user) ->
      user = _user
      done()
    .fail (log)


  beforeEach ->
    sync = new Sync(user)

  describe '#basic', ->

    it 'should add lists and tasks', (done) ->

      # Create three lists
      promise = Q.all [
        sync.list_create name: 'List 1'
        sync.list_create name: 'List 2'
        sync.list_create name: 'List 3'
      ]

      promise.then (_lists) ->

        # Save list ids
        lists = _lists

        # Check lists exist
        Q.all [
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
        Q.all [
          sync.task_create name: 'Task 1', listId: lists[0]
          sync.task_create name: 'Task 2', listId: lists[0]
          sync.task_create name: 'Task 3', listId: lists[0]
        ]

      .then (_tasks) ->

        # Save task ids
        tasks = _tasks

        # Check tasks exists
        Q.all [
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

      .fail(log)


    it 'should handle task and list updates', (done) ->

      # Update task names
      promise = Q.all [
        sync.task_update id: tasks[0], name: 'Task 1 has been renamed'
        sync.task_update id: tasks[1], name: 'Task 2 has been renamed'
        sync.task_update id: tasks[2], name: 'Task 3 has been renamed'
      ]

      promise.then ->

        Q.all [
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
        Q.all [
          sync.list_update id: lists[0], name: 'List 1 has been renamed'
          sync.list_update id: lists[1], name: 'List 2 has been renamed'
          sync.list_update id: lists[2], name: 'List 3 has been renamed'
        ]

      .then ->

        Q.all [
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

      .fail(log)


    it 'should move a task to another list', (done) ->

      promise = Q.all [
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

        Q.all [
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

      .fail(log)


  describe '#timestamps', ->

    # Travel 10 seconds back in time!
    past = time.now() - 10

    it 'should respect timestamps - task', (done) ->

      sync.task_update({
        id: tasks[0], name: 'Task 1 in the past'
      }, {
        name: past
      }).fail (err) ->
        err.should.equal 'err_old_event'
        done()

    it 'should respect timestamps - list', (done) ->

      sync.list_update({
        id: lists[1], name: 'List 2 in the past'
      },{
        name: past
      }).fail (err) ->
        err.should.equal 'err_old_event'
        done()

    it 'should respect timestamps - pref', (done) ->

      sync.pref_update({
        sort: false
      }, {
        sort: past
      }).fail (err) ->
        err.should.equal 'err_old_event'
        done()


  describe '#non-existant-models', ->

    it 'should fail when updating a non-existant task', (done) ->

      promise = sync.task_update
        id: tasks[2] + 10
        name: 'Task 4'

      promise.fail -> done()

    it 'should fail when updating a non-existant list', (done) ->

      promise = sync.list_update
        id: lists[2] + 10
        name: 'List 4'

      promise.fail -> done()


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

      .fail (err) ->

        err.should.equal 'err_no_row'
        user.readListTasks lists[1]

      .then (tasks) ->

        tasks.should.eql []

        # Destroy two lists
        Q.all [
          sync.list_destroy lists[1]
          sync.list_destroy lists[2]
        ]

      .then ->

        # Check that the lists have been deleted
        user.readList lists[1]
      .fail (err) ->
        err.should.equal 'err_no_row'
        user.readList lists[2]
      .fail (err) ->
        err.should.equal 'err_no_row'

        # Destroy the last list that still has tasks in it
        sync.list_destroy lists[0]

      .then ->

        # Check that everything has been deleted
        user.readList lists[0]
      .fail (err) ->
        err.should.equal 'err_no_row'
        user.readTask tasks[1]
      .fail (err) ->
        err.should.equal 'err_no_row'
        user.readTask tasks[2]
      .fail (err) ->
        err.should.equal 'err_no_row'

        done()

      .fail(log)


    it 'should fail when destroying a non-existant task', (done) ->

      sync.task_destroy(tasks[2] + 10).fail -> done()

    it 'should fail when destroying a non-existant list', (done) ->

      sync.list_destroy(lists[2] + 10).fail -> done()
