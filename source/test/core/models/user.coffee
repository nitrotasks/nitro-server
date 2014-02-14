require('should')
setup = require('../../setup')
User  = require('../../../core/models/user')

describe 'User', ->

  user = null

  before (done) ->
    setup()
    .then(setup.createUser)
    .then -> done()
    .done()

  beforeEach ->
    user = new User(setup.userId)

  describe ':read', ->

    it 'should read a single column', (done) ->

      user.read('name')
      .then (data) ->
        data.should.eql
          name: 'user_name'
      .then -> done()
      .done()

    it 'should read multiple columns', (done) ->

      user.read(['name', 'password'])
      .then (data) ->
        data.should.eql
          name: 'user_name'
          password: 'user_password'
      .then -> done()
      .done()

    it 'should read all the columns', (done) ->

      user.read()
      .then (user) ->
        user.id.should.equal setup.userId
        user.name.should.equal('user_name')
        user.email.should.match(/^user_email_\d+$/)
        user.password.should.equal('user_password')
        user.created_at.should.be.a.Date
        user.pro.should.equal(0)
      .then -> done()
      .done()

    it 'should throw err when user does not exist', (done) ->

      user = new User(-1)
      user.read()
      .catch (err) ->
        err.message.should.equal('err_no_row')
        done()
      .done()

  describe ':update', ->

    it 'should update a single column', (done) ->

      user.update(name: 'user_name_updated')
      .then ->
        user.read('name')
      .then (data) ->
        data.should.eql
          name: 'user_name_updated'
      .then -> done()
      .done()

    it 'should throw err when user does not exist', (done) ->

      user = new User(-1)
      user.update(name: 'user_name_updated')
      .catch (err) ->
        err.message.should.equal('err_no_row')
        done()
      .done()

    it 'should throw err when column does not exist', (done) ->

      user.update(fake: 'err')
      .catch (err) ->
        err.message.should.eql('err_could_not_update_row')
        done()
      .done()

  describe ':destroy', ->

    it 'should destroy a user', (done) ->

      user.destroy()
      .then ->
        user.read()
      .catch (err) ->
        err.message.should.eql 'err_no_row'
        done()
      .done()

    it 'should throw err when the user does not exist', (done) ->

      user = new User(-1)
      user.destroy()
      .catch (err) ->
        err.message.should.equal 'err_no_row'
        done()
      .done()

