Q = require 'kew'
should = require 'should'
database = require '../app/controllers/query'

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
    user_id: null
    name: 'List 1'

  task =
    user_id: null
    list_id: null
    name: 'Task 1'
    notes: 'Some notes'
    priority: 2
    date: 0
    completed: 0

  before setup

  describe '#user', ->

    it 'should create a new user', (done) ->

      database.user.create(user).then (id) ->
        id.should.be.a.Number
        user.id = id
        done()

    it 'should store the creation time', (done) ->

      database.user.read(user.id, 'created_at').then (info) ->
        info.created_at.should.be.an.instanceOf Date
        user.created_at = info.created_at
        done()

    it 'should fetch all user information', (done) ->

      database.user.read(user.id).then (info) ->
        info.should.eql user
        done()

    it 'should update an existing user', (done) ->

      user.name = 'James'
      model = name: user.name
      database.user.update(user.id, model).then -> done()

    it 'should fetch a updated information', (done) ->

      database.user.read(user.id, 'name').then (info) ->
        info.name.should.equal user.name
        done()

    it 'should fetch multiple values', (done) ->

      database.user.read(user.id, ['name', 'email']).then (info) ->
        info.should.eql
          name: user.name
          email: user.email
        done()

    it 'should delete an existing user', (done) ->

      database.user.destroy(user.id).then -> done()

    it 'should fail when fetching a user that does not exist', (done) ->

      database.user.read(user.id, 'name').fail -> done()

    it 'should fail when updating a user that does not exist', (done) ->

      model = email: 'james@gmail.com'
      database.user.update(user.id, model).fail (err) ->
        err.should.equal 'err_no_row'
        done()

    it 'should fail when destroying a user that does not exist', (done) ->

      database.user.destroy(user.id).fail -> done()

    it 'should create another user', (done) ->

      delete user.id
      delete user.created_at

      database.user.create(user).then (id) ->
        user.id = id
        done()


  describe '#list', ->


    before ->
      list.user_id = user.id

    it 'should create a new list', (done) ->

      database.list.create(list).then (id) ->
        list.id = id
        done()

    it 'should read an existing list', (done) ->

      database.list.read(list.id).then (info) ->
        info.should.eql list
        done()

    it 'should update an existing list', (done) ->

      list.name = 'List 1 - Updated'
      model = name: list.name
      database.list.update(list.id, model).then -> done()

    it 'should read an updated list', (done) ->

      database.list.read(list.id, 'name').then (info) ->
        info.should.eql
          name: list.name
        done()

    it 'should destroy an existing list', (done) ->

      database.list.destroy(list.id).then -> done()

    it 'should create another list', (done) ->

      delete list.id
      database.list.create(list).then (id) ->
        list.id = id
        done()


  describe '#task', ->

    before ->
      task.user_id = user.id
      task.list_id = list.id

    it 'should create a new task', (done) ->

      database.task.create(task).then (id) ->
        task.id = id
        done()

    it 'should read an existing task', (done) ->

      database.task.read(task.id).then (info) ->
        task.should.eql info
        done()

    it 'should update an existing task', (done) ->

      task.name = 'Task 1 - Updated'
      model = name: task.name
      database.task.update(task.id, model).then -> done()

    it 'should read an updated task', (done) ->

      database.task.read(task.id, 'name').then (info) ->
        info.name.should.equal task.name
        done()

    it 'should destroy an existing task', (done) ->

      database.task.destroy(task.id).then -> done()

    it 'should create another task', (done) ->

      delete task.id
      database.task.create(task).then (id) ->
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

      database.register.create(entry).then (_token) ->
        token = _token
        token.should.match /^\d+_\w+$/
        done()

    it 'should read an existing entry', (done) ->

      database.register.read(token).then (info) ->
        info.should.eql
          name: user.name
          email: user.email
          password: user.password
        done()

    it 'should fail when it cannot find a registration', (done) ->

      database.register.read(user.id + '_gibberish').fail (err) ->
        err.should.equal 'err_no_row'
        done()

    it 'should fail when it cannot parse a token', (done) ->

      database.register.read('nonsense').fail (err) ->
        err.should.equal 'err_invalid_token'
        done()

    it 'should destroy an existing token', (done) ->

      database.register.destroy(token).then -> done()

    it 'should fail when destroying a token that does not exist', (done) ->

      database.register.destroy(user.id + '_gibberish').fail (err) ->
        err.should.equal 'err_no_row'
        done()



  describe '#pref', ->

    pref =
      user_id: null
      sort: 0
      night: 0
      language: 'en-NZ'
      weekStart: 1
      dateFormat: 'dd/mm/yy'
      confirmDelete: 1
      moveCompleted: 1

    before ->
      pref.user_id = user.id

    it 'should create a new pref', (done) ->

      database.pref.create(pref).then -> done()

    it 'should only allow one pref per user', (done) ->

      database.pref.create(pref).fail -> done()

    it 'should update a pref', (done) ->

      pref.sort = 1
      changes = sort: pref.sort

      database.pref.update(user.id, changes).then ->
        done()

    it 'should read from a pref', (done) ->

      database.pref.read(user.id).then (info) ->
        info.should.eql pref
        done()

    it 'should destroy a pref', (done) ->

      database.pref.destroy(user.id).then ->
        done()



  describe '#list_tasks', ->

    it 'should add a task to a list', (done) ->

      database.listTasks.create(list.id, task.id).then -> done()

    it 'should read all tasks from a list', (done) ->

      database.listTasks.read(list.id).then (tasks) ->
        tasks.should.eql [ task.id ]
        done()

    it 'should remove a task from a list', (done) ->

      database.listTasks.destroy(list.id, task.id).then -> done()

    it 'should return an empty array when there are no tasks', (done) ->

      database.listTasks.read(list.id).then (tasks) ->
        tasks.should.eql []
        done()

    it 'should add the same task to the same list again', (done) ->

      database.listTasks.create(list.id, task.id).then -> done()

    it 'should remove all tasks from a list', (done) ->

      database.listTasks.destroyAll(list.id)
        .then ->
          database.listTasks.read(list.id)
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

      database.login.create(login.id, login.token).then -> done()

    it 'should read the date the login token was created', (done) ->

      database.login.read(login.id, login.token, 'created_at').then (info) ->
        login.created_at = info.created_at
        login.created_at.should.be.an.instanceOf Date
        done()

    it 'should read an existing entry', (done) ->

      database.login.read(login.id, login.token).then (info) ->
        info.should.eql
          user_id: login.id
          token: login.token
          created_at: login.created_at
        done()

    it 'should check if a login exists', (done) ->

      database.login.exists(login.id, login.token).then (exists) ->
        exists.should.equal true
        done()

    it 'should destroy an existing entry', (done) ->

      database.login.destroy(login.id, login.token).then -> done()

    it 'should check if a login does not exist', (done) ->

      database.login.exists(login.id, login.token).then (exists) ->
        exists.should.equal false
        done()

    it 'should fail when reading an entry that does not exist', (done) ->

      database.login.read(login.id, login.token).fail (err) ->
        err.should.equal 'err_no_row'
        done()

    it 'should create another login token', (done) ->

      database.login.create(login.id, login.token)
      .then ->
        database.login.create(login.id, 'temp')
      .then ->
        database.login.create(login.id, 'orary')
      .then ->
        done()

    it 'should delete all login token', (done) ->

      Q.all([
        database.login.exists login.id, login.token
        database.login.exists user.id, 'temp'
        database.login.exists user.id, 'orary'

        database.login.destroyAll(user.id)

        database.login.exists login.id, login.token
        database.login.exists user.id, 'temp'
        database.login.exists user.id, 'orary'
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

      database.reset.create(reset.id, reset.token).then (_token) ->
        token = _token
        token.should.match /^\d+_\w+$/
        done()

    it 'should read a reset token', (done) ->

      database.reset.read(token).then (id) ->
        id.should.equal reset.id
        done()

    it 'should fail when using an invalid token', (done) ->

      database.reset.read('blah').fail (err) ->
        err.should.equal 'err_invalid_token'
        done()

    it 'should destroy a reset token', (done) ->

      database.reset.destroy(token).then -> done()

    it 'should fail when reading a token that does not exist', (done) ->

      database.reset.read(token).fail (err) ->
        err.should.equal 'err_no_row'
        done()

