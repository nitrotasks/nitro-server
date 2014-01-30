User    = require '../app/models/user'
Storage = require '../app/controllers/storage'
setup   = require './setup'
should  = require 'should'
Log = require '../app/utils/log'

log = Log 'user - test'

describe 'User', ->

  _user =
    name: 'The User'
    email: 'user@inter.net'
    password: 'hunter2'

  user = {}

  before (done) -> setup ->
    Storage.add(_user).then (_user) ->
      user.id = _user.id
      done()

  beforeEach ->
    user = new User(user.id)

  describe '#info', ->

    it 'read', (done) ->

      user.info().then (info) ->
        info.should.eql
          name: _user.name
          email: _user.email
          pro: _user.pro
        done()


  describe '#name', ->

    it 'set', (done) ->

      user.setName('Bruce Wayne').then ->
        done()

    it 'get', (done) ->

      user.getName().then (name) ->
        name.should.equal 'Bruce Wayne'
        done()


  describe '#email', ->

    it 'set', (done) ->

      user.setEmail('bruce@batman.com').then ->
        done()

    it 'get', (done) ->

      user.getEmail().then (email) ->
        email.should.equal 'bruce@batman.com'
        done()


  describe '#password', ->

    it 'set', (done) ->

      user.setPassword('batmobile').then ->
        done()

    it 'get', (done) ->

      user.getPassword().then (password) ->
        password.should.equal 'batmobile'
        done()


  describe '#create', ->

    listId = null

    it 'list', (done) ->

      user.createList({
        name: 'Things to do'
      }).then (id) ->
        id.should.be.a.Number
        listId = id
        done()

    it 'task', (done) ->

      user.createTask({
        name: 'Save the world'
        listId: listId
      }).then (id) ->
        id.should.be.a.Number
        done()

    it 'pref', (done) ->

      # Storage.add automatically creates a pref for us
      user.destroyPref()
      .then ->
        user.createPref({
          sort: 1
        })
      .then ->
        done()
      .fail(log)


  describe '#listTasks', ->

    listId = null
    taskId = null

    before (done) ->

      user.createList({ name: 'The best list ever' })
      .then (id) ->
        listId = id
        user.createTask({ name: 'The best task ever', listId: id })
      .then (id) ->
        taskId = id
        done()

    it 'add', (done) ->

      user.addTaskToList(taskId, listId).then ->
        done()

    it 'get', (done) ->

      user.readListTasks(listId).then (tasks) ->
        tasks.should.eql [ taskId ]
        done()

    it 'remove', (done) ->

      user.removeTaskFromList(taskId, listId)
      .then ->
        user.readListTasks(listId)
      .then (tasks) ->
        tasks.should.eql []
        done()


  describe '#shouldOwn', ->

    listId = null
    taskId = null

    before (done) ->

      user.createList({ name: 'We own this list' })
      .then (id) ->
        listId = id
        user.createTask({ name: 'We own this task', listId: id })
      .then (id) ->
        taskId = id
        done()

    it 'task - does own', (done) ->

      user.shouldOwnTask(taskId).then ->
        done()

    it 'task - does not own', (done) ->

      user.shouldOwnTask(-200).fail (err) ->
        err.should.equal 'err_no_row'
        done()

    it 'list - does own', (done) ->

      user.shouldOwnList(listId).then ->
        done()

    it 'list - does not own', (done) ->

      user.shouldOwnList(-200).fail (err) ->
        err.should.equal 'err_no_row'
        done()

  describe '#read', ->

    listId = null
    taskId = null

    before (done) ->

      user.createList({ name: 'Going to read this list' })
      .then (id) ->
        listId = id
        user.createTask({
          listId: id
          name: 'Going to read this task'
          notes: 'My private notes'
          priority: 2
          date: 1337
          completed: 0
        })
      .then (id) ->
        taskId = id
        done()

    it 'task - all rows', (done) ->

     user.readTask(taskId).then (task) ->
      task.should.eql
        id: taskId
        listId: listId
        name: 'Going to read this task'
        notes: 'My private notes'
        priority: 2
        date: 1337
        completed: 0
      done()

    it 'task - partial rows', (done) ->

     user.readTask(taskId, ['name', 'completed']).then (task) ->
      task.should.eql
        name: 'Going to read this task'
        completed: 0
      done()

    it 'list - all rows', (done) ->

      user.readList(listId).then (list) ->
        list.should.eql
          id: listId
          name: 'Going to read this list'
        done()

    it 'list - single row', (done) ->

      user.readList(listId, 'name').then (list) ->
        list.should.eql
          name: 'Going to read this list'
        done()

    it 'pref - all rows', (done) ->

      user.readPref().then (pref) ->
        pref.should.eql
          sort: 1
          night: null
          language: null
          weekStart: null
          dateFormat: null
          confirmDelete: null
          moveCompleted: null
        done()

    it 'pref - single row', (done) ->

      user.readPref('sort').then (pref) ->
        pref.should.eql
          sort: 1
        done()


  describe '#update', ->

    listId = null
    taskId = null

    before (done) ->

      user.createList({ name: 'Original List' })
      .then (id) ->
        listId = id
        user.createTask({ name: 'Original Task', listId: id })
      .then (id) ->
        taskId = id
        done()

    it 'task - exists', (done) ->

      user.updateTask(taskId, { name: 'Updated Task' })
      .then ->
        user.readTask(taskId, 'name')
      .then (task) ->
        task.name.should.equal 'Updated Task'
        done()

    it 'task - does not exist', (done) ->

      user.updateTask(-200, { name: 'Updated task'}).fail (err) ->
        err.should.eql 'err_no_row'
        done()

    it 'list - exists', (done) ->

      user.updateList(listId, { name: 'Updated List' })
      .then ->
        user.readList(listId, 'name')
      .then (list) ->
        list.name.should.equal 'Updated List'
        done()

    it 'list - does not exist', (done) ->

      user.updateList(-200, { name: 'Updated list'}).fail (err) ->
        err.should.eql 'err_no_row'
        done()

    it 'pref', (done) ->

      user.updatePref({ moveCompleted: 1 })
      .then ->
        user.readPref('moveCompleted')
      .then (pref) ->
        pref.moveCompleted.should.equal 1
        done()

  describe '#destroy', ->

    listId = null
    taskId = null

    before (done) ->

      user.createList({ name: 'List to be destroyed' })
      .then (id) ->
        listId = id
        user.createTask({ name: 'Task to be destroyed', listId: id })
      .then (id) ->
        taskId = id
        done()

    it 'task - exists', (done) ->

      user.destroyTask(taskId)
      .then ->
        user.readTask(taskId)
      .fail (err) ->
        err.should.equal 'err_no_row'
        done()

    it 'task - does not exist', (done) ->

      user.destroyTask(-200).fail (err) ->
        err.should.eql 'err_no_row'
        done()

    it 'list - exists', (done) ->

      user.destroyList(listId)
      .then ->
        user.readList(listId)
      .fail (err) ->
        err.should.equal 'err_no_row'
        done()

    it 'list - does not exist', (done) ->

      user.destroyList(-200).fail (err) ->
        err.should.eql 'err_no_row'
        done()

    it 'pref', (done) ->

      user.destroyPref()
      .then ->
        user.readPref()
      .fail (err) ->
        err.should.equal 'err_no_row'
        done()

  describe '#export', ->

    listId = null
    taskId = null

    before (done) ->

      user.createList({ name: 'The Last List' })
      .then (id) ->
        listId = id
        user.createTask({ name: 'The Last Task', listId: id })
      .then (id) ->
        taskId = id
        user.addTaskToList(taskId, listId)
      .then ->
        user.createPref
          sort: 1
          night: 2
          language: 'en-NZ'
          weekStart: 0
          dateFormat: 'dd/mm/yy'
          confirmDelete: 0
          moveCompleted: 1
      .then ->
        done()

    it 'task', (done) ->

      user.exportTasks().then (tasks) ->
        tasks.should.be.an.Array
        for task in tasks when task.id is taskId
          task.should.eql
            id: taskId
            listId: listId
            name: 'The Last Task'
            notes: null
            date: null
            completed: null
            priority: null
        done()
      .fail(log)

    it 'list', (done) ->

      user.exportLists().then (lists) ->
        lists.should.be.an.Array
        for list in lists when list is listId
          list.should.eql
            id: listId
            name: 'The Last List'
            tasks: [ taskId ]
        done()
      .fail(log)

    it 'pref', (done) ->

      user.exportPref().then (pref) ->
        pref.should.eql
          sort: 1
          night: 2
          language: 'en-NZ'
          weekStart: 0
          dateFormat: 'dd/mm/yy'
          confirmDelete: 0
          moveCompleted: 1
        done()

