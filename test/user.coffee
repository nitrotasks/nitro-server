User = require '../app/user'
Storage = require '../app/storage'
assert = require 'assert'

global.DebugMode = true

Storage.writeUser = ->

describe 'User class', ->

  it 'should create a new user', ->
    user = new User()

  it 'should create a new using with pre-defined attributes', ->

    attrs =
      id: 30
      name: 'Johnny'
      data_task:
        football: true
      created_at: Date.now()

    user = new User(attrs)

    assert.equal attrs.id,          user.id
    assert.equal attrs.name,        user.name
    assert.equal attrs.data_task,   user.data_task
    assert.equal attrs.created_at,  user.created_at

  it 'should allow attributes to be changed', ->

    name = 'Timothy'
    user = new User()

    value = user.set 'name', name

    assert.equal name, user.name
    assert.equal value, name

  it 'should throttle writes to the db', (done) ->

    @timeout 6000

    start = Date.now()

    fn = Storage.writeUser
    count = 0

    Storage.writeUser = (user, args) ->

      switch count++
        when 0
          assert.deepEqual args, ['tasks']

        when 1
          assert.deepEqual args, ['lists', 'name', 'email']
          diff = Date.now() - start
          assert diff >= 5000
          assert diff <= 5005
          Storage.writeUser = fn
          done()

    user = new User()
    user.save 'tasks'
    user.save 'lists'
    user.save 'name'
    user.save 'email'

  it 'should get and set data', ->

    user = new User()

    data = user.data 'animals'
    assert.deepEqual data, {}

    data.horses = 1

    data = user.data 'animals'
    assert.equal data.horses, 1

    user.data 'animals',
      horses: 30

    data = user.data 'animals'
    assert.equal data.horses, 30

  it 'should get the index value', ->

    user = new User()

    index = user.index 'cows'
    assert.equal index, 0

    user.set 'index_chickens', 30

    index = user.index 'chickens'
    assert.equal index, 30

  it 'should increment the index value', ->

    user = new User()

    index = user.index 'pigs'
    assert.equal index, 0

    index = user.incrIndex 'pigs'
    assert.equal index, 1

    index = user.incrIndex 'pigs'
    assert.equal index, 2

  it 'should allow the password to be changed', (done) ->

    id = 300
    password = 'battery horse chicken staple'

    Storage.removeAllLoginTokens = (userId) ->
      assert.equal userId, id
      assert.equal password, user.password
      done()

    user = new User
      id: id
      password: 'hunter2'

    user.setPassword password

  it 'should allow the email to be changed', (done) ->

    id = 33
    email = 'john@smith.com'

    Storage.replaceEmail = (userId, oldEmail, newEmail) ->
      assert.equal userId, id
      assert.equal newEmail, user.email
      assert.equal email, user.email
      done()

    user = new User
      id: id
      email: 'john@gmail.com'

    user.setEmail email





