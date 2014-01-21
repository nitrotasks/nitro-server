Q        = require 'kew'
should   = require 'should'
setup    = require './setup'
Storage  = require '../app/controllers/storage'
redis    = require '../app/controllers/redis'

users = [
  {name: 'stayradiated',  email: 'george@czabania.com',   password: 'abc'}
  {name: 'consindo',      email: 'jono@jonocooper.com',   password: 'xkcd'}
  {name: 'nitroman',      email: 'user@nitrotaks.com',    password: 'hunter2'}
]

log = console.log.bind(console)

describe 'Storage API >', ->

  before setup


# -----------------------------------------------------------------------------
# Adding Users
# -----------------------------------------------------------------------------

  it 'should be able to add users', (done) ->
    users.forEach (user, i, array) ->
      Storage.add(user)
        .then (data) ->
          data.name.should.equal       user.name
          data.email.should.equal      user.email
          data.password.should.equal   user.password
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

  it 'should get users by email', (done) ->

    users.forEach (user, i, array) ->
      Storage.getByEmail(user.email)
        .then (data) ->
          user.email.should.equal data.email
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
          user.name.should.equal          _user.name
          user.email.should.equal         _user.email
          user.password.should.equal  _user.password
          if i is array.length - 1 then done()
        .fail(log)


# -----------------------------------------------------------------------------
# Login Tokens
# -----------------------------------------------------------------------------

  do ->

    user = users[0]
    token = 'hogwarts'

    it 'add', (done) ->
      console.log 'user.id', user.id
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
      Storage.removeLoginToken(user.id, token)
        .then ->
          Storage.checkLoginToken(user.id, token)
        .then (exists) ->
          exists.should.be.false
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
          err.should.equal 'err_no_user'
          done()

    it 'check new email has been added', (done) ->
      Storage.getByEmail(user.email)
        .then (_user) ->
          _user.name.should.equal user.name
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

        tasks.should.equal _user.data 'task'
        lists.should.equal _user.data 'list'

        _user.save('task', 'list')
          .then ->
            done()
          .fail(log)

    it 'should release users from memory', (done) ->

      Storage.release(user.id)
        .then ->
          Storage.get(user.id)
        .then (_user) ->
          tasks.should.eql _user.data 'task'
          _user.data('task')[1].name = 'task 1 - Changed'
          done()

    it 'should handle data indexes properly', (done) ->

      Storage.get(user.id)
        .then (_user) ->
          index = _user.index 'tasks'
          index.should.equal 0
          (++index).should.equal _user.incrIndex 'tasks'
          (++index).should.equal _user.incrIndex 'tasks'
          index.should.equal _user.index 'tasks'
          done()
        .fail(log)


# -----------------------------------------------------------------------------
# Releasing Users
# -----------------------------------------------------------------------------

  it 'should be able to release users from JS memory', (done) ->

    user = users[2]
    length = Object.keys(Storage.records).length

    Storage.records[user.id].should.not.equal undefined

    Storage.release(user.id).then ->

      should.strictEqual Storage.records[user.id], undefined
      Object.keys(Storage.records).should.have.length --length
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
          token.should.equal token
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
