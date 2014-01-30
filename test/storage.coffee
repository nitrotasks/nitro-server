Q        = require 'kew'
should   = require 'should'
setup    = require './setup'
Storage  = require '../app/controllers/storage'
time     = require '../app/utils/time'
Log = require '../app/utils/log'

log = Log 'storage - test'

users = [
  {name: 'stayradiated',  email: 'george@czabania.com',   password: 'abc'}
  {name: 'consindo',      email: 'jono@jonocooper.com',   password: 'xkcd'}
  {name: 'nitroman',      email: 'user@nitrotaks.com',    password: 'hunter2'}
]

describe 'Storage API >', ->

  before setup


# -----------------------------------------------------------------------------
# Adding Users
# -----------------------------------------------------------------------------

  describe 'Add Users', ->

    it 'should be able to add users', (done) ->
      users.forEach (user, i, array) ->
        Storage.add(user)
          .then (user) ->
            user.id.should.be.a.Number
            # Save user ID so we can use it future tests
            users[i].id = user.id
            if i is array.length - 1 then done()
          .fail(log)

    it 'should not allow duplicate email addresses', (done) ->
      users.forEach (user, i, array) ->
        Storage.add(user).fail (err) ->
          err.should.equal 'err_old_email'
          if i is array.length - 1 then done()


# -----------------------------------------------------------------------------
# Checking Existing Users
# -----------------------------------------------------------------------------

  describe 'Check Existing Users', ->

    it 'emailExists should return false if an email doesn\'t exist', (done) ->

      Storage.emailExists('joe@smith.com')
        .then (exists) ->
          exists.should.be.false
          done()
        .fail(log)


    it 'emailExists should return true if an email exists', (done) ->

      users.forEach (user, i, array) ->
        Storage.emailExists(user.email).then (exists) ->
          exists.should.be.true
          if i is array.length - 1 then done()


# -----------------------------------------------------------------------------
# Retrieve Users
# -----------------------------------------------------------------------------

  describe 'Retrieve Users', ->

    it 'should get users by email', (done) ->

      users.forEach (data, i, array) ->
        Storage.getByEmail(data.email).then (user) ->

          user.info().then (info) ->
            info.should.eql
              name: data.name
              email: data.email
              pro: data.pro
            if i is array.length - 1 then done()

        .fail(log)

    it 'should fail if you try and get a non-existant user by email', (done) ->

      Storage.getByEmail('john@example.com')
        .fail (err) ->
          done()

    it 'should get users by id', (done) ->

      users.forEach (data, i, array) ->
        Storage.get(data.id).then (user) ->
          user.info().then (info) ->
            info.should.eql
              name: data.name
              email: data.email
              pro: data.pro
            if i is array.length - 1 then done()


# -----------------------------------------------------------------------------
# Login Tokens
# -----------------------------------------------------------------------------

  describe 'Login Tokens', ->

    user = users[0]
    token = 'hogwarts'

    it 'add', (done) ->
      Storage.addLoginToken(user.id, token)
        .then ->
          done()
        .fail(log)

    it 'check exists', (done) ->
      Storage.checkLoginToken(user.id, token)
        .then (exists) ->
          exists.should.be.true
          done()
        .fail(log)

    it 'check does not exist', (done) ->
      Storage.checkLoginToken(user.id, token + 'x')
        .then (exists) ->
          exists.should.be.false
          done()
        .fail(log)

    it 'remove', (done) ->
      Storage.destroyLoginToken(user.id, token)
        .then ->
          Storage.checkLoginToken(user.id, token)
        .then (exists) ->
          exists.should.be.false
          done()
        .fail(log)

# -----------------------------------------------------------------------------
# Reset Password
# -----------------------------------------------------------------------------

  describe 'Reset Password', ->

    user = users[0]
    token = 'a1b2c3d4e5'

    it 'create reset token', (done) ->
      Storage.addResetToken(user.id, token).then (_token) ->
        token = _token
        token.should.match(/^\d+_\w+$/)
        done()

    it 'should check if a reset token exists', (done) ->
      Storage.checkResetToken(token).then (_id) ->
        user.id.should.equal _id
        done()

    it 'should fail check if reset token does not exist', (done) ->
      Storage.checkResetToken('12_abcd').fail (err) ->
        err.should.equal 'err_bad_token'
        done()

    it 'should fail check if reset token is corrupt', (done) ->
      Storage.checkResetToken('random').fail (err) ->
        err.should.equal 'err_bad_token'
        done()

    it 'should destroy reset token', (done) ->
      Storage.destroyResetToken(token).then ->
        done()

    it 'should not fail destroy if reset token does not exist', (done) ->
      Storage.destroyResetToken('12_abcd').then -> done()

    it 'should fail destroy if reset token is not correct', (done) ->
      Storage.destroyResetToken('random').fail (err) ->
        err.should.eql 'err_bad_token'
        done()

# -----------------------------------------------------------------------------
# User Data
# -----------------------------------------------------------------------------

  describe 'User Data', ->

    tasks = [
      name: 'Task 1'
      date: time.now()
      priority: '2'
      notes: 'Just some notes'
      completed: 0
    ,
      name: 'Task 2'
      date: time.now()
      priority: '1'
      notes: 'Not many notes'
      completed: 0
    ]

    lists = [
      name: 'list 1'
    ,
      name: 'list 2'
    ]

    user = users[1]

    before (done) ->
      Storage.get(user.id).then (_user) ->
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

# -----------------------------------------------------------------------------
# Deleting Users
# -----------------------------------------------------------------------------

  describe 'Deleting Users', ->

    it 'should be able to delete users from disk', (done) ->

      users.forEach (user, i, array) ->
        Storage.destroy(user.id).then ->
          if i is array.length - 1 then done()

    it 'should not be able to find deleted users', (done) ->

      users.forEach (user, i, array) ->
        Storage.get(user.id).fail ->
          if i is array.length - 1 then done()


# -----------------------------------------------------------------------------
# Registration
# -----------------------------------------------------------------------------

  describe 'Registration', ->

    user =
      name: 'George'
      email: 'mail@example.com'
      password: 'abc123'

    token = '1234567890'

    it 'Register User', (done) ->

      Storage.register(token, user.name, user.email, user.password)
        .then (_token) ->
          _token.match(/\d+_(\w+)/)[1].should.equal token
          token = _token
          done()
        .fail(log)

    it 'Get Registration', (done) ->

      Storage.getRegistration(token)
        .then (data) ->
          user.name.should.equal data.name
          user.email.should.equal data.email
          user.password.should.equal data.password
          done()
        .fail(log)

    it 'Missing Token', (done) ->

      Storage.getRegistration('abc')
        .fail (err) ->
          err.should.equal 'err_bad_token'
          done()
