assert = require 'assert'
User = require '../app/user'
Q = require 'q'

User._redis.flushdb()
global.DebugMode = true

users = [
  {name: 'stayradiated', email: 'george@czabania.com', password: 'password'}
  {name: 'consindo', email: 'jono@jonocooper.com', password: 'another password'}
  {name: 'teqnoqolor', email: 'dev@stayradiated.com', password: 'drowssap'}
]

describe 'Storage API', ->

  it 'should be able to add users', (done) ->

    console.log '\n Add Users \n'

    users.forEach (user, i, array) ->
      User.add(user).then (data) ->
        assert.equal data.name, user.name
        assert.equal data.email, user.email
        assert.equal data.password, user.password
        if i is array.length - 1 then done()

  it 'should not allow duplicate email addresses', (done) ->
    users.forEach (user, i, array) ->
      User.add(user).fail (e) ->
        if i is array.length - 1 then done()

  it 'emailExists should return false if an email doesn\'t exist', (done) ->
    User.emailExists('joe@smith.com').then (exists) ->
      assert.equal exists, false
      done()

  it 'emailExists should return true if an email exists', (done) ->
    users.forEach (user, i, array) ->
      User.emailExists(user.email).then (exists) ->
        assert.equal exists, true
        if i is array.length - 1 then done()

  it 'should get users by email', (done) ->

    console.log '\n Users By Email \n'

    users.forEach (user, i, array) ->
      User.getByEmail(user.email)
        .then (data) ->
          assert.equal user.email, data.email
          # Save user ID so we can use it future tests
          users[i].id = data.id
          if i is array.length - 1 then done()
        .fail (err) ->
          console.log 'ERROR', err

  it 'should fail if you try and get a non-existant user by email', (done) ->

    console.log '\n Users By Email \n'

    User.getByEmail('john@example.com')
      .then (data) ->
        console.log data
      .fail (err) ->
        done()

  it 'should let users change their password', (done) ->

    console.log '\n Change Password \n'

    Q.all([
      User.get(users[0].id)
      User.get(users[0].id)
    ]).then ([u1, u2]) ->
      u1.setPassword 'my-new-password'
      assert.equal 'my-new-password', u1.password
      assert.equal 'my-new-password', u2.password
      done()

  it 'should let users change their email address', (done) ->

    console.log '\n Change Email \n'

    user = users[1]
    newEmail = user.email = 'example@mail.com'

    Q.all([
      User.get(user.id)
      User.get(user.id)
    ]).then ([u1, u2]) ->
      u1.setEmail(newEmail)
        .then ->
          assert.equal newEmail, u1.email, u2.email
        .then ->
          User.getByEmail(newEmail)
        .then (u3) ->
          assert.equal u3.name, user.name
          done()

  it 'should let users change their pro status', (done) ->

    console.log '\n Change Pro \n'

    hasPro = '1'
    user = users[1]
    Q.all([
      User.get(user.id)
      User.get(user.id)
    ]).then ([u1, u2]) ->
      u2.setPro hasPro
      assert.equal hasPro, u1.pro, u2.pro
      done()

  it 'should save user data', (done) ->

    console.log '\n Save User Data \n'

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

    Q.all([
      User.get(user.id)
      User.get(user.id)
    ]).then ([u1, u2]) ->

      u1.data('task', tasks)
      u1.save('task')

      u2.data('list', lists)
      u2.save('list')

      assert.equal tasks, u1.data('task'), u2.data('task')
      assert.equal lists, u1.data('list'), u2.data('list')

      # Release the user
      # This forces User.get() to fetch the data from disk
      User.release(user.id)
      User.get(user.id).then (u3) ->
        assert.deepEqual tasks, u3.data 'task'
        u3.data('task')[1].name = 'task 1 - Changed'
        u3.save()
        done()

  it 'should increment data index', (done) ->

    console.log '\n Increment Data Index \n'

    user = users[1]
    User.get(user.id).then (user) ->
      index = user.index 'Fake'
      user.incrIndex 'Fake'
      assert.equal ++index, user.index 'Fake'
      user.incrIndex 'Fake'
      assert.equal ++index, user.index 'Fake'
      done()

  it 'should be able to release users from JS memory', (done) ->

    console.log '\n Release Users \n'

    user = users[2]
    assert.notEqual User.records[user.id], undefined
    User.release(user.id).then ->
      assert.equal User.records[user.id], undefined
      done()

  it 'should be able to delete users from disk', (done) ->

    console.log '\n Delete From Disk \n'

    users.forEach (user, i, array) ->
      User.remove(user.id)
        .then ->
          User.get(user.id)
        .fail ->
          if i is array.length - 1 then done()

  it 'should register users temporarily until verified', (done) ->

    console.log '\n Register User \n'

    user =
      name: 'George'
      email: 'mail@example.com'
      password: 'abc123'

    User.register('1234567890', user)
      .then (token) ->
        User.getRegistration token
      .then (data) ->
        assert.equal user.name, data.name
        assert.equal user.email, data.email
        assert.equal user.password, data.password
        done()

  it 'should fail if registration token is not found', (done) ->

    console.log '\n Miss Registration \n'

    User.getRegistration('abc').fail (err) ->
      assert.equal err.message, 'err_bad_token'
      done()
