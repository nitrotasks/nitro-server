User   = require '../app/models/user'
Users  = require '../app/controllers/users'
setup  = require './setup'
should = require 'should'
Time   = require '../app/utils/time'
Log    = require '../app/utils/log'

log = Log 'user - test'

describe 'User', ->

  _user =
    name: 'The User'
    email: 'user@inter.net'
    password: 'hunter2'
    pro: 0

  user =
    id: null

  before (done) -> setup ->
    Users.create(_user).then (_user) ->
      user.id = _user.id
      done()

  beforeEach ->
    user = new User(user.id)

# -----------------------------------------------------------------------------
# User Info
# -----------------------------------------------------------------------------

  describe '#info', ->

    it 'read', (done) ->

      user.info().then (info) ->
        info.should.eql
          name: _user.name
          email: _user.email
          pro: _user.pro
        done()


# -----------------------------------------------------------------------------
# User Name
# -----------------------------------------------------------------------------

  describe '#name', ->

    it 'set', (done) ->

      user.setName('Bruce Wayne').then ->
        done()

    it 'get', (done) ->

      user.getName().then (name) ->
        name.should.equal 'Bruce Wayne'
        done()


# -----------------------------------------------------------------------------
# User Email
# -----------------------------------------------------------------------------

  describe '#email', ->

    it 'set', (done) ->

      user.setEmail('bruce@batman.com').then ->
        done()

    it 'get', (done) ->

      user.getEmail().then (email) ->
        email.should.equal 'bruce@batman.com'
        done()

# -----------------------------------------------------------------------------
# User Password
# -----------------------------------------------------------------------------

  describe '#password', ->

    it 'set', (done) ->

      user.setPassword('batmobile').then ->
        done()

    it 'get', (done) ->

      user.getPassword().then (password) ->
        password.should.equal 'batmobile'
        done()


# -----------------------------------------------------------------------------
# User Create Task/List/Pref
# -----------------------------------------------------------------------------

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
      .done()


# -----------------------------------------------------------------------------
# User Add Task to List
# -----------------------------------------------------------------------------

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


# -----------------------------------------------------------------------------
# User Should Own
# -----------------------------------------------------------------------------

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

      user.shouldOwnTask(-200).catch (err) ->
        err.should.equal 'err_no_row'
        done()

    it 'list - does own', (done) ->

      user.shouldOwnList(listId).then ->
        done()

    it 'list - does not own', (done) ->

      user.shouldOwnList(-200).catch (err) ->
        err.should.equal 'err_no_row'
        done()


# -----------------------------------------------------------------------------
# User Read Task/List/Pref
# -----------------------------------------------------------------------------

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


# -----------------------------------------------------------------------------
# User Update Task/List/Pref
# -----------------------------------------------------------------------------

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

      user.updateTask(-200, { name: 'Updated task'}).catch (err) ->
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

      user.updateList(-200, { name: 'Updated list'}).catch (err) ->
        err.should.eql 'err_no_row'
        done()

    it 'pref', (done) ->

      user.updatePref({ moveCompleted: 1 })
      .then ->
        user.readPref('moveCompleted')
      .then (pref) ->
        pref.moveCompleted.should.equal 1
        done()


# -----------------------------------------------------------------------------
# User Destroy Task/List/Pref
# -----------------------------------------------------------------------------

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
      .catch (err) ->
        err.should.equal 'err_no_row'
        done()

    it 'task - does not exist', (done) ->

      user.destroyTask(-200).catch (err) ->
        err.should.eql 'err_no_row'
        done()

    it 'list - exists', (done) ->

      user.destroyList(listId)
      .then ->
        user.readList(listId)
      .catch (err) ->
        err.should.equal 'err_no_row'
        done()

    it 'list - does not exist', (done) ->

      user.destroyList(-200).catch (err) ->
        err.should.eql 'err_no_row'
        done()

    it 'pref', (done) ->

      user.destroyPref()
      .then ->
        user.readPref()
      .catch (err) ->
        err.should.equal 'err_no_row'
        done()


# -----------------------------------------------------------------------------
# User Export Task/List/Pref
# -----------------------------------------------------------------------------

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
      .done()

    it 'list', (done) ->

      user.exportLists().then (lists) ->
        lists.should.be.an.Array
        for list in lists when list is listId
          list.should.eql
            id: listId
            name: 'The Last List'
            tasks: [ taskId ]
        done()
      .done()

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

# -----------------------------------------------------------------------------
# User Add/Remove Data
# -----------------------------------------------------------------------------

  describe 'User Data', ->

    tasks = [
      name: 'Task 1'
      date: Time.now()
      priority: '2'
      notes: 'Just some notes'
      completed: 0
    ,
      name: 'Task 2'
      date: Time.now()
      priority: '1'
      notes: 'Not many notes'
      completed: 0
    ]

    lists = [
      name: 'list 1'
    ,
      name: 'list 2'
    ]

    before (done) ->
      Users.read(user.id).then (_user) ->
        user = _user
        done()


    it 'should create the first list', (done) ->

      list = lists[0]

      user.createList(list).then (id) ->
        list.id = id
        done()

    it 'should read the first list', (done) ->

      list = lists[0]

      user.readList(list.id).then (data) ->
        data.should.eql
          id: list.id
          name: list.name
        done()

    it 'should own first the list', (done) ->

      list = lists[0]

      user.shouldOwnList(list.id).then -> done()

    it 'should create the second list', (done) ->

      list = lists[1]

      user.createList(list).then (id) ->
        list.id = id
        done()

    it 'should read the second list', (done) ->

      list = lists[1]

      user.readList(list.id).then (data) ->
        data.should.eql
          id: list.id
          name: list.name
        done()

    it 'should create the first task', (done) ->

      task = tasks[0]
      task.listId = lists[0].id

      user.createTask(task).then (id) ->
        task.id = id
        done()

    it 'should read the first task', (done) ->

      task = tasks[0]

      user.readTask(task.id).then (data) ->
        data.should.eql task
        done()

    it 'should create the second task', (done) ->

      task = tasks[1]
      task.listId = lists[1].id

      user.createTask(task).then (id) ->
        task.id = id
        done()

    it 'should read the second task', (done) ->

      task = tasks[1]

      user.readTask(task.id).then (data) ->
        data.should.eql task
        done()