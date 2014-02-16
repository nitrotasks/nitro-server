should   = require('should')
Promise  = require('bluebird')
setup    = require('../setup')
auth     = require('../../core/controllers/auth')
Users    = require('../../core/models/user')

describe 'Auth', ->

  before (done) ->
    setup()
    .then(setup.createUser)
    .then -> done()
    .done()

  beforeEach (done) ->
    Users.destroyAll()
    .then ->
      auth.register(setup._user.name, setup._user.email, setup._user.password)
    .spread (id, token) ->
      setup.user = new Users.User(id)
    .then -> done()
    .done()

  describe ':register', ->

    beforeEach (done) ->
      Users.destroyAll()
      .then -> done()
      .done()

    user =
      name: 'user_name'
      email: 'user_email'
      pass: 'user_password'

    it 'should throw err_bad_name when registering', (done) ->

      auth.register('', user.email, user.pass)
      .catch (err) ->
        err.message.should.equal 'err_bad_name'
        done()
      .done()

    it 'should throw err_bad_email when registering', (done) ->

      auth.register(user.name, '', user.pass)
      .catch (err) ->
        err.message.should.equal 'err_bad_email'
        done()
      .done()

    it 'should throw err_bad_pass when registering', (done) ->

      auth.register(user.name, user.email, '')
      .catch (err) ->
        err.message.should.equal 'err_bad_pass'
        done()
      .done()

    it 'should be able to register a user', (done) ->

      auth.register(user.name, user.email, user.pass)
      .spread (id, token) ->
        id.should.be.a.Number
        token.should.be.a.String
        token.should.have.length(64)
        token.should.match /^[\w-]+$/
      .then -> done()
      .done()

  describe ':login', ->

    it 'should return the user id and token', (done) ->

      auth.login(setup._email, setup._user.password)
      .spread (id, token) ->
        id.should.be.a.Number
        token.should.be.a.String
        token.should.have.length(64)
      .then -> done()
      .done()

    it 'should throw err if password does not match email', (done) ->

      auth.login(setup._user.email, 'hunter2')
      .catch (err) ->
        err.message.should.equal 'err_bad_pass'
        done()
      .done()

  describe ':createResetToken', ->

    it 'should add a reset token for a user', (done) ->

      auth.createResetToken(setup._user.email)
      .then (token) ->
        token.should.match(/\w/) # TODO: fix this
      .then -> done()
      .done()

    it 'should fail if token does not exist', (done) ->

      auth.createResetToken('bad_token')
      .catch (err) ->
        err.message.should.equal('err_no_row')
        done()
      .done()

  describe ':changePassword', ->

    it 'should change the users password', (done) ->

      original = null

      setup.user.read('password').get('password')
      .then (hash) ->
        original = hash
        auth.changePassword(setup.user, 'potatopie')
      .then ->
        setup.user.read('password').get('password')
      .then (hash) ->
        original.should.not.equal(hash)
        auth.login(setup._email, 'potatopie')
      .spread (id, token) ->
        id.should.equal(setup.user.id)
      .then -> done()
      .done()



