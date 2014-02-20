should      = require('should')
setup       = require('../setup')
token       = require('../../server/controllers/token')
GuestSocket = require('../../server/sockets/guest')
Sandal      = require('./sandal')

describe 'UserSocket', ->

  client = null
  socket = null

  before (done) ->
    setup()
    .then(setup.createUser)
    .then(Sandal.setup)
    .then -> done()
    .done()

  beforeEach (done) ->

    sessionToken = token.createSocketToken(setup.userId)

    client = new Sandal()
    socket = new GuestSocket(client.serverSocket)

    client.emit 'user.auth', sessionToken, (err, user) ->
      should.equal(err, null)
      done()

  afterEach ->
    client.end()

  describe ':user', ->

    describe ':info', ->

      it 'should get user info', (done) ->

        client.emit 'user.info', (err, user) ->
          user.should.have.keys('id', 'name', 'email', 'pro', 'created_at')

          user.id.should.equal(setup.userId)
          user.name.should.equal(setup._user.name)
          user.email.should.equal(setup._user.email)
          user.pro.should.equal(setup._user.pro)
          user.created_at.should.be.a.Date

          done()

  describe ':list', ->

    beforeEach (done) ->
      setup.createList()
      .then(setup.createTimeList)
      .then -> done()
      .done()

    describe ':create', ->

      it 'should create a new list', (done) ->

        list =
          name: 'list_name'

        client.emit 'list.create', list, (err, list) ->
          list.should.have.keys('id', 'userId', 'name')
          done()

    describe ':update', ->

      it 'should update a list', (done) ->

        changes =
          name: 'list_name_changed'

        client.emit 'list.update', setup.listId, changes, (err, list) ->
          list.should.have.keys('id', 'userId', 'name')
          done()

    describe ':destroy', ->

      it 'should destroy a list', (done) ->

        data =
          id: setup.listId

        client.emit 'list.destroy', data, (err, success) ->
          success.should.equal(true)
          done()

  describe ':task', ->

    beforeEach (done) ->
      setup.createList()
      .then(setup.createTask)
      .then(setup.createTimeTask)
      .then -> done()
      .done()

    describe ':create', ->

      it 'should create a task', (done) ->

        data =
          listId: setup.listId
          name: 'list_name'
          notes: ''
          date: 0
          priority: 0
          completed: 0

        client.emit 'task.create', data, (err, task) ->
          should.equal(null, err)

          data.id = task.id
          data.userId = setup.userId
          task.should.eql(data)

          done()

    describe ':update', ->

    describe ':destroy', ->

  describe ':pref', ->

    describe ':update', ->

