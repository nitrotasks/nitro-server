Sync   = require '../app/controllers/sync'
Auth   = require '../app/controllers/auth'
setup  = require './setup'
should = require 'should'
Q      = require 'kew'


LIST = 'list'
TASK = 'task'
PREF = 'pref'


describe 'Sync API', ->

  user = null
  sync = null

  lists = []
  tasks = []


  before (done) -> setup ->
    Auth.register('George', 'mail@example.com', 'password')
    .then (token) ->
      Auth.verifyRegistration(token)
    .then (_user) ->
      user = _user
      done()
    .fail (err) ->
      console.log err


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
        user.exportLists()

      .then (_lists) ->

        _lists.should.eql [
          { name: 'List 1', tasks: [], id: lists[0] }
          { name: 'List 2', tasks: [], id: lists[1] }
          { name: 'List 3', tasks: [], id: lists[2] }
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
        user.exportTasks()

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
        _tasks.should.eql tasks
        done()

      .fail (err) ->
        console.log err


    it 'should handle task and list updates', (done) ->

      # Update task names
      promise = Q.all [
        sync.task_update id: tasks[0], name: 'Task 1 has been renamed'
        sync.task_update id: tasks[1], name: 'Task 2 has been renamed'
        sync.task_update id: tasks[2], name: 'Task 3 has been renamed'
      ]

      promise.then ->

        user.exportTasks()

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

        user.exportLists()

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

      .fail (err) ->
        console.log err
        console.log err.stack


    it 'should move a task to another list', (done) ->

      promise = Q.all [
        user.exportLists()
        user.exportTasks()
      ]

      promise.then ([_lists, _tasks]) ->

        _tasks[0].listId.should.equal lists[0]
        _lists[0].tasks.should.eql tasks
        _lists[1].tasks.should.eql []

        # Move task
        sync.task_update
          id: tasks[0]
          listId: lists[1]

      .then ->

        Q.all [
          user.exportLists()
          user.exportTasks()
        ]

      .then ([_lists, _tasks]) ->

        # Check task has been moved
        _tasks[0].listId.should.equal lists[1]
        _lists[0].tasks.should.eql [tasks[1], tasks[2]]
        _lists[1].tasks.should.eql [tasks[0]]

        done()

      .fail (err) ->
        console.log err


  describe '#timestamps', ->

    # Travel 10 seconds back in time!
    past = Date.now() - 1000 * 10

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

      .fail (err) ->
        console.log err


    it 'should fail when destroying a non-existant task', (done) ->

      sync.task_destroy(tasks[2] + 10).fail -> done()

    it 'should fail when destroying a non-existant list', (done) ->

      sync.list_destroy(lists[2] + 10).fail -> done()
