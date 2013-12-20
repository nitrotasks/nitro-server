Q = require 'q'
assert = require 'assert'
connect = require '../app/controllers/connect'
database = require '../app/controllers/database'
Storage = require '../app/controllers/storage'

global.DebugMode = true
connect.init 'testing'

users = [
  {name: 'stayradiated', email: 'george@czabania.com', password: 'abc'}
  {name: 'consindo', email: 'jono@jonocooper.com', password: 'xkcd'}
  {name: 'teqnoqolor', email: 'dev@stayradiated.com', password: 'hunter2'}
]

log = console.log.bind(console)

describe 'Storage API >', ->


# -----------------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------------

  before (done) ->

    promise = Q.all [
      connect.ready
      database.connected
    ]

    promise
      .then ->
        connect.redis.flushdb()
        database.truncate 'users'
      .then ->
        done()

# -----------------------------------------------------------------------------
# Adding Users
# -----------------------------------------------------------------------------

  it 'should be able to add users', (done) ->
    users.forEach (user, i, array) ->
      Storage.add(user)
        .then (data) ->
          assert.equal data.name, user.name
          assert.equal data.email, user.email
          assert.equal data.password, user.password
          if i is array.length - 1 then done()
        .fail(log)

  it 'should not allow duplicate email addresses', (done) ->
    users.forEach (user, i, array) ->
      Storage.add(user).fail (err) ->
        assert.equal err, 'err_old_email'
        if i is array.length - 1 then done()


# -----------------------------------------------------------------------------
# Checking Existing Users
# -----------------------------------------------------------------------------

  it 'emailExists should return false if an email doesn\'t exist', (done) ->

    Storage.emailExists('joe@smith.com')
      .then (exists) ->
        assert.equal exists, false
        done()
      .fail(log)

  it 'emailExists should return true if an email exists', (done) ->

    users.forEach (user, i, array) ->
      Storage.emailExists(user.email).then (exists) ->
        assert.equal exists, true
        if i is array.length - 1 then done()


# -----------------------------------------------------------------------------
# Retrieve Users
# -----------------------------------------------------------------------------

  it 'should get users by email', (done) ->

    users.forEach (user, i, array) ->
      Storage.getByEmail(user.email)
        .then (data) ->
          assert.equal user.email, data.email
          # Save user ID so we can use it future tests
          users[i].id = data.id
          if i is array.length - 1 then done()
        .fail(log)

  it 'should fail if you try and get a non-existant user by email', (done) ->

    Storage.getByEmail('john@example.com')
      .then (data) ->
        console.log data
      .fail (err) ->
        done()

  it 'should get users by id', (done) ->

    users.forEach (user, i, array) ->
      Storage.get(user.id)
        .then (_user) ->
          assert.equal user.name, _user.name
          assert.equal user.email, _user.email
          assert.equal user.password, _user.password
          if i is array.length - 1 then done()
        .fail(log)


# -----------------------------------------------------------------------------
# Login Tokens
# -----------------------------------------------------------------------------

  do ->

    id = 200
    token = 'hogwarts'

    it 'add', (done) ->
      Storage.addLoginToken(id, token)
        .then ->
          done()
        .fail(log)

    it 'check exists', (done) ->
      Storage.checkLoginToken(id, token)
        .then (exists) ->
          assert.equal exists, true
          done()
        .fail(log)

    it 'remove', (done) ->
      Storage.removeLoginToken(id, token)
        .then ->
          Storage.checkLoginToken(id, token)
        .then (exists) ->
          assert.equal exists, false
          done()
        .fail(log)


# -----------------------------------------------------------------------------
# Change Email Address
# -----------------------------------------------------------------------------

  do ->

    user = oldEmail = null

    it 'changing', (done) ->

      user = users[1]
      oldEmail = user.email
      user.email = 'example@mail.com'

      Storage.replaceEmail(user.id, oldEmail, user.email)
        .then ->
          done()
        .fail(log)

    it 'check old email has been removed', (done) ->
      Storage.getByEmail(oldEmail)
        .fail (err) ->
          assert.equal err, 'err_no_user'
          done()

    it 'check new email has been added', (done) ->
      Storage.getByEmail(user.email)
        .then (_user) ->
          assert.equal _user.name, user.name
          done()
        .fail(log)


# -----------------------------------------------------------------------------
# User Data
# -----------------------------------------------------------------------------

  do ->

    tasks =
      '1':
        name: 'Task 1'
        date: 1355863711107
        priority: '2'
        notes: 'Just some notes'
      '2':
        name: 'Task 2'
        date: 1355863711407
        priority: '1'
        notes: 'Not many notes'

    lists =
      '1':
        name: 'list 1'
      '2':
        name: 'list 2'

    user = users[1]

    it 'should save user data to disk', (done) ->

      Storage.get(user.id).then (_user) ->
        _user.data 'task', tasks
        _user.data 'list', lists

        assert.equal tasks, _user.data 'task'
        assert.equal lists, _user.data 'list'

        _user.save('task', 'list')
          .then ->
            done()
          .fail(log)

    it 'should release users from memory', (done) ->

      Storage.release(user.id)
        .then ->
          Storage.get(user.id)
        .then (_user) ->
          assert.deepEqual tasks, _user.data 'task'
          _user.data('task')[1].name = 'task 1 - Changed'
          done()

    it 'should handle data indexes properly', (done) ->

      Storage.get(user.id)
        .then (_user) ->
          index = _user.index 'tasks'
          assert.equal index, 0
          assert.equal ++index, _user.incrIndex 'tasks'
          assert.equal ++index, _user.incrIndex 'tasks'
          assert.equal index, _user.index 'tasks'
          done()
        .fail(log)


# -----------------------------------------------------------------------------
# Releasing Users
# -----------------------------------------------------------------------------

  it 'should be able to release users from JS memory', (done) ->

    user = users[2]
    length = Object.keys(Storage.records).length

    assert.notEqual Storage.records[user.id], undefined

    Storage.release(user.id).then ->
      assert.equal Storage.records[user.id], undefined
      assert.equal length - 1, Object.keys(Storage.records).length
      done()


# -----------------------------------------------------------------------------
# Deleting Users
# -----------------------------------------------------------------------------

  it 'should be able to delete users from disk', (done) ->

    users.forEach (user, i, array) ->
      Storage.remove(user.id).then ->
        if i is array.length - 1 then done()

  it 'should not be able to find deleted users', (done) ->

    users.forEach (user, i, array) ->
      Storage.get(user.id).fail ->
        if i is array.length - 1 then done()


# -----------------------------------------------------------------------------
# Registration
# -----------------------------------------------------------------------------

  do ->

    user =
      name: 'George'
      email: 'mail@example.com'
      password: 'abc123'

    token = '1234567890'

    it 'Register User', (done) ->

      Storage.register(token, user.name, user.email, user.password)
        .then (_token) ->
          assert.equal _token, token
          done()
        .fail(log)

    it 'Get Registration', (done) ->

      Storage.getRegistration(token)
        .then (data) ->
          assert.equal user.name, data.name
          assert.equal user.email, data.email
          assert.equal user.password, data.password
          done()
        .fail(log)

    it 'Missing Token', (done) ->

      Storage.getRegistration('abc')
        .fail (err) ->
          assert.equal err, 'err_bad_token'
          done()
