should  = require('should')
setup   = require('../../setup')
db      = require('../../../core/controllers/database')

describe 'Database', ->

  before (done) ->
    setup()
    .then(setup.createUser)
    .then -> done()
    .done()

  beforeEach (done) ->
    db.user.destroy(setup.userId)
    .then(setup.createUser)
    .then -> done()
    .done()

  describe ':user', ->

    describe ':create', ->

      userId = null

      beforeEach (done) ->
        db.user.destroy(setup.userId)
        .then -> done()
        .done()

      afterEach (done) ->
        db.user.destroy(userId)
        .then -> done()
        .done()

      it 'should create a new user', (done) ->

        db.user.create(setup._user)
        .then (id) ->
          userId = id
          id.should.be.a.Number
        .then -> done()
        .done()

    describe ':exists', ->

      it 'should check if user exists', (done) ->

        db.user.exists(setup.userId).then (exists) ->
          exists.should.equal(true)
        .then -> done()
        .done()

      it 'should check if a user does not exist', (done) ->

        db.user.destroy(setup.userId)
        .then ->
          db.user.exists(setup.userId)
        .then (exists) ->
          exists.should.equal(false)
        .then -> done()
        .done()

    describe ':read', ->

      it 'should store the creation time', (done) ->

        db.user.read(setup.userId, 'created_at')
        .then (info) ->
          info.created_at.should.be.an.instanceOf(Date)
        .then -> done()
        .done()

      it 'should fetch multiple values', (done) ->

        db.user.read(setup.userId, ['name', 'email'])
        .then (info) ->
          info.should.eql
            name: 'user_name'
            email: 'user_email'
        .then -> done()
        .done()

      it 'should fetch all user information', (done) ->

        db.user.read(setup.userId)
        .then (info) ->
          info.id.should.equal(setup.userId)
          info.name.should.equal(setup._user.name)
          info.email.should.equal(setup._user.email)
          info.password.should.equal(setup._user.password)
          info.created_at.should.be.a.Date
        .then -> done()
        .done()

      it 'should throw err when fetching a user that does not exist', (done) ->

        db.user.destroy(setup.userId)
        .then ->
          db.user.read(setup.userId, 'name')
        .catch (err) ->
          err.message.should.equal 'err_no_row'
          done()
        .done()

    describe ':update', ->

      it 'should update an existing user', (done) ->

        db.user.update setup.userId,
          name: 'user_name_updated'
        .then ->
          db.user.read(setup.userId, 'name')
        .then (info) ->
          info.name.should.equal('user_name_updated')
        .then -> done()
        .done()

      it 'should throw err when updating a user that does not exist', (done) ->

        db.user.destroy(setup.userId)
        .then ->
          db.user.update setup.userId,
            name: 'user_name_updated'
        .catch (err) ->
          err.message.should.equal 'err_no_row'
          done()
        .done()

    describe ':destroy', ->

      it 'should delete an existing user', (done) ->

        db.user.destroy(setup.userId)
        .then ->
          db.user.read(setup.userId)
        .catch (err) ->
          err.message.should.equal('err_no_row')
          done()
        .done()

      it 'should not throw err when destroying a user that does not exist', (done) ->

        db.user.destroy(setup.userId)
        .then ->
          db.user.destroy(setup.userId)
        .then -> done()
        .done()
