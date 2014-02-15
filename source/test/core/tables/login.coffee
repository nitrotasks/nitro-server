should  = require('should')
setup   = require('../../setup')
db      = require('../../../core/controllers/database')

describe 'Database', ->

  before (done) ->
    setup()
    .then(setup.createUser)
    .then(setup.createLogin)
    .then -> done()
    .done()

  beforeEach (done) ->
    db.login.destroyAll(setup.loginId)
    .then(setup.createLogin)
    .then -> done()
    .done()

  describe ':login', ->

    describe ':create', ->

      beforeEach (done) ->
        db.login.destroyAll(setup.loginId)
        .then -> done()
        .done()

      it 'should create a new entry', (done) ->

        db.login.create(setup._login.id, setup._login.token)
        .then -> done()
        .done()

      it 'should create another login token', (done) ->

        db.login.create(setup.userId, setup._login.token)
        .then ->
          db.login.create(setup.userId, 'login_token_2')
        .then ->
          db.login.create(setup.userId, 'login_token_3')
        .then ->
          db.login.readAll(setup.userId)
        .then (tokens) ->
          tokens.length.should.equal(3)
          tokens[0].token.should.equal('login_token')
          tokens[1].token.should.equal('login_token_2')
          tokens[2].token.should.equal('login_token_3')
        .then -> done()
        .done()

    describe ':read', ->

      it 'should read the date the login token was created', (done) ->

        db.login.read(setup.userId, setup._login.token)
        .then (login) ->
          login.userId.should.equal(setup.userId)
          login.token.should.equal(setup._login.token)
          login.created_at.should.be.an.instanceOf(Date)
        .then -> done()
        .done()

      it 'should throw err when reading an entry that does not exist', (done) ->

        db.login.destroyAll(setup.userId)
        .then ->
          db.login.read(setup.userId, setup._login.token)
        .catch (err) ->
          err.message.should.equal 'err_no_row'
        .then -> done()
        .done()

    describe ':exists', ->

      it 'should check if a login exists', (done) ->

        db.login.exists(setup.userId, setup._login.token)
        .then (exists) ->
          exists.should.equal(true)
        .then -> done()
        .done()

    describe ':destroy', ->

      it 'should destroy an existing entry', (done) ->

        db.login.destroy(setup.userId, setup._login.token)
        .then ->
          db.login.read(setup.userId, setup._login.token)
        .catch (err) ->
          err.message.should.equal('err_no_row')
        .then -> done()
        .done()

      it 'should check if a login does not exist', (done) ->

        db.login.destroyAll(setup.userId)
        .then ->
          db.login.exists(setup.userId, setup._login.token)
        .then (exists) ->
          exists.should.equal(false)
        .then -> done()
        .done()

    describe ':destroyAll', (done) ->

      it 'should delete all login token', (done) ->

        db.login.destroyAll(setup.userId)
        .catch (err) ->
          throw new Error 'could not destroy tokens'
        .then ->
          db.login.readAll(setup.userId)
        .catch (err) ->
          err.message.should.equal('err_no_row')
        .then -> done()
        .done()

