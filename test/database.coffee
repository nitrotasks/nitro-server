Q = require 'kew'
should = require 'should'
db = require '../app/controllers/query'

setup   = require './setup'
should  = require 'should'

# Testing the database storage engine

describe 'Database', ->

  user =
    name: 'Jimmy'
    email: 'jimmy@gmail.com'
    password: 'blah'
    pro: 0

  list =
    userId: null
    name: 'List 1'

  task =
    userId: null
    listId: null
    name: 'Task 1'
    notes: 'Some notes'
    priority: 2
    date: 0
    completed: 0

  before setup

  describe '#user', ->

    it 'should create a new user', (done) ->

      db.user.create(user).then (id) ->
        id.should.be.a.Number
        user.id = id
        done()

    it 'should check if user exists', (done) ->

      db.user.exists(user.id).then (exists) ->
        exists.should.equal true
        done()

    it 'should store the creation time', (done) ->

      db.user.read(user.id, 'created_at').then (info) ->
        info.created_at.should.be.an.instanceOf Date
        user.created_at = info.created_at
        done()

    it 'should fetch all user information', (done) ->

      db.user.read(user.id).then (info) ->
        info.should.eql user
        done()

    it 'should update an existing user', (done) ->

      user.name = 'James'
      model = name: user.name
      db.user.update(user.id, model).then -> done()

    it 'should fetch a updated information', (done) ->

      db.user.read(user.id, 'name').then (info) ->
        info.name.should.equal user.name
        done()

    it 'should fetch multiple values', (done) ->

      db.user.read(user.id, ['name', 'email']).then (info) ->
        info.should.eql
          name: user.name
          email: user.email
        done()

    it 'should delete an existing user', (done) ->

      db.user.destroy(user.id).then -> done()

    it 'should check if a user does not exist', (done) ->

      db.user.exists(user.id).then (exists) ->
        exists.should.equal false
        done()

    it 'should fail when fetching a user that does not exist', (done) ->

      db.user.read(user.id, 'name').fail -> done()

    it 'should fail when updating a user that does not exist', (done) ->

      model = email: 'james@gmail.com'
      db.user.update(user.id, model).fail (err) ->
        err.should.equal 'err_no_row'
        done()

    it 'should fail when destroying a user that does not exist', (done) ->

      db.user.destroy(user.id).fail -> done()

    it 'should create another user', (done) ->

      delete user.id
      delete user.created_at

      db.user.create(user).then (id) ->
        user.id = id
        done()


  describe '#list', ->


    before ->
      list.userId = user.id

    it 'should create a new list', (done) ->

      db.list.create(list).then (id) ->
        list.id = id
        done()

    it 'should read an existing list', (done) ->

      db.list.read(list.id).then (info) ->
        info.should.eql list
        done()

    it 'should update an existing list', (done) ->

      list.name = 'List 1 - Updated'
      model = name: list.name
      db.list.update(list.id, model).then -> done()

    it 'should read an updated list', (done) ->

      db.list.read(list.id, 'name').then (info) ->
        info.should.eql
          name: list.name
        done()

    it 'should destroy an existing list', (done) ->

      db.list.destroy(list.id).then -> done()

    it 'should create another list', (done) ->

      delete list.id
      db.list.create(list).then (id) ->
        list.id = id
        done()


  describe '#task', ->

    before ->
      task.userId = user.id
      task.listId = list.id

    it 'should create a new task', (done) ->

      db.task.create(task).then (id) ->
        task.id = id
        done()

    it 'should read an existing task', (done) ->

      db.task.read(task.id).then (info) ->
        task.should.eql info
        done()

    it 'should update an existing task', (done) ->

      task.name = 'Task 1 - Updated'
      model = name: task.name
      db.task.update(task.id, model).then -> done()

    it 'should read an updated task', (done) ->

      db.task.read(task.id, 'name').then (info) ->
        info.name.should.equal task.name
        done()

    it 'should destroy an existing task', (done) ->

      db.task.destroy(task.id).then -> done()

    it 'should create another task', (done) ->

      delete task.id
      db.task.create(task).then (id) ->
        task.id = id
        done()


  describe '#register', ->

    token = null

    it 'should create a new entry', (done) ->

      entry =
        token: 'reddit'
        name: user.name
        email: user.email
        password: user.password

      db.register.create(entry).then (_token) ->
        token = _token
        token.should.match /^\d+_\w+$/
        done()

    it 'should read an existing entry', (done) ->

      db.register.read(token).then (info) ->
        info.should.eql
          id: token.match(/(\d+)_/)[1]
          name: user.name
          email: user.email
          password: user.password
        done()

    it 'should fail when it cannot find a registration', (done) ->

      db.register.read(user.id + '_gibberish').fail (err) ->
        err.should.equal 'err_no_row'
        done()

    it 'should fail when it cannot parse a token', (done) ->

      db.register.read('nonsense').fail (err) ->
        err.should.equal 'err_invalid_token'
        done()

    it 'should destroy an existing token', (done) ->

      db.register.destroy(token).then -> done()

    it 'should fail when destroying a token that does not exist', (done) ->

      db.register.destroy(user.id + '_gibberish').fail (err) ->
        err.should.equal 'err_no_row'
        done()



  describe '#pref', ->

    pref =
      userId: null
      sort: 0
      night: 0
      language: 'en-NZ'
      weekStart: 1
      dateFormat: 'dd/mm/yy'
      confirmDelete: 1
      moveCompleted: 1

    before ->
      pref.userId = user.id

    it 'should create a new pref', (done) ->

      db.pref.create(pref).then -> done()

    it 'should only allow one pref per user', (done) ->

      db.pref.create(pref).fail -> done()

    it 'should update a pref', (done) ->

      pref.sort = 1
      changes = sort: pref.sort

      db.pref.update(user.id, changes).then ->
        done()

    it 'should read from a pref', (done) ->

      db.pref.read(user.id).then (info) ->
        info.should.eql pref
        done()

    it 'should destroy a pref', (done) ->

      db.pref.destroy(user.id).then ->
        done()



  describe '#list_tasks', ->

    it 'should add a task to a list', (done) ->

      db.listTasks.create(list.id, task.id).then -> done()

    it 'should read all tasks from a list', (done) ->

      db.listTasks.read(list.id).then (tasks) ->
        tasks.should.eql [ task.id ]
        done()

    it 'should remove a task from a list', (done) ->

      db.listTasks.destroy(list.id, task.id).then -> done()

    it 'should return an empty array when there are no tasks', (done) ->

      db.listTasks.read(list.id).then (tasks) ->
        tasks.should.eql []
        done()

    it 'should add the same task to the same list again', (done) ->

      db.listTasks.create(list.id, task.id).then -> done()

    it 'should remove all tasks from a list', (done) ->

      db.listTasks.destroyAll(list.id)
        .then ->
          db.listTasks.read(list.id)
        .then (tasks) ->
          tasks.should.eql []
          done()



  describe '#login', ->

    login =
      id: null
      token: 'battery-horse-staple'

    before ->
      login.id = user.id

    it 'should create a new entry', (done) ->

      db.login.create(login.id, login.token).then -> done()

    it 'should read the date the login token was created', (done) ->

      db.login.read(login.id, login.token, 'created_at').then (info) ->
        login.created_at = info.created_at
        login.created_at.should.be.an.instanceOf Date
        done()

    it 'should read an existing entry', (done) ->

      db.login.read(login.id, login.token).then (info) ->
        info.should.eql
          userId: login.id
          token: login.token
          created_at: login.created_at
        done()

    it 'should check if a login exists', (done) ->

      db.login.exists(login.id, login.token).then (exists) ->
        exists.should.equal true
        done()

    it 'should destroy an existing entry', (done) ->

      db.login.destroy(login.id, login.token).then -> done()

    it 'should check if a login does not exist', (done) ->

      db.login.exists(login.id, login.token).then (exists) ->
        exists.should.equal false
        done()

    it 'should fail when reading an entry that does not exist', (done) ->

      db.login.read(login.id, login.token).fail (err) ->
        err.should.equal 'err_no_row'
        done()

    it 'should create another login token', (done) ->

      db.login.create(login.id, login.token)
      .then ->
        db.login.create(login.id, 'temp')
      .then ->
        db.login.create(login.id, 'orary')
      .then ->
        done()

    it 'should delete all login token', (done) ->

      Q.all([
        db.login.exists login.id, login.token
        db.login.exists user.id, 'temp'
        db.login.exists user.id, 'orary'

        db.login.destroyAll(user.id)

        db.login.exists login.id, login.token
        db.login.exists user.id, 'temp'
        db.login.exists user.id, 'orary'
      ]).then ([a, b, c, _, x, y, z]) ->
        a.should.equal true
        b.should.equal true
        c.should.equal true
        x.should.equal false
        y.should.equal false
        z.should.equal false
        done()
      .fail (err) ->
        console.log err


  describe '#reset', ->

    token = null

    reset =
      id: null
      token: 'actually'

    before ->
      reset.id = user.id

    it 'should create a reset token' , (done) ->

      db.reset.create(reset.id, reset.token).then (_token) ->
        token = _token
        token.should.match /^\d+_\w+$/
        done()

    it 'should read a reset token', (done) ->

      db.reset.read(token).then (id) ->
        id.should.equal reset.id
        done()

    it 'should fail when using an invalid token', (done) ->

      db.reset.read('blah').fail (err) ->
        err.should.equal 'err_invalid_token'
        done()

    it 'should destroy a reset token', (done) ->

      db.reset.destroy(token).then -> done()

    it 'should fail when reading a token that does not exist', (done) ->

      db.reset.read(token).fail (err) ->
        err.should.equal 'err_no_row'
        done()



  describe '#task_and_lists', ->

    it 'should require tasks to have a list', (done) ->

      model =
        userId: user.id
        listId: 2000
        name: 'Task 2'

      db.task.create(model).fail -> done()

    it 'should deleting a task should remove it from a list', (done) ->

      task =
        id: null
        userId: user.id
        listId: list.id
        name: 'Task 3'

      # Create a new task
      db.task.create(task)
      .then (id) ->
        task.id = id

      # Add the task to the list
        db.listTasks.create(list.id, task.id)
      .then ->

      # Check that we have added the task
        db.listTasks.read(list.id)
      .then (tasks) ->
        tasks.should.eql [ task.id ]

      # Destroy the task
        db.task.destroy(task.id)
      .then ->

      # Check that the task is no longer in the list
        db.listTasks.read(list.id)
      .then (tasks) ->
        tasks.should.eql []
        done()
