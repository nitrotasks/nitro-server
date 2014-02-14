require('should')
setup = require('../../setup')
Users = require('../../../core/models/user')

describe 'Users', ->

  before (done) ->
    setup()
    .then(setup.createUser)
    .then -> done()
    .done()

  beforeEach (done) ->
    Users.destroyAll()
    .then(setup.createUser)
    .then -> done()
    .done()


  describe ':create', ->

    it 'should be able to add users', (done) ->

      Users.create
        name: 'user_name'
        email: 'user_email'
        password: 'user_password'
        pro: 1
      .then (user) ->
        user.id.should.be.a.Number
      .then -> done()
      .done()

    it 'should not allow duplicate email addresses', (done) ->

      user =
        name: 'user_name'
        email: 'user_email'
        password: 'user_password'
        pro: 1

      Users.create(user)
      .then ->
        Users.create(user)
      .catch (err) ->
        err.message.should.equal 'err_old_email'
        done()
      .done()

  describe ':exists', ->

    it 'should return false if an email does not exist', (done) ->

      Users.emailExists(-1)
      .then (exists) ->
        exists.should.equal(false)
      .then -> done()
      .done()

    it 'should return true if an email exists', (done) ->

      Users.get(setup.userId)
      .call('read')
      .then (user) ->
        Users.emailExists(user.email)
      .then (exists) ->
        exists.should.equal(true)
      .then -> done()
      .done()

  describe ':search', ->

    email = null

    beforeEach (done) ->
      Users.get(setup.userId)
      .call('read', 'email')
      .then (user) ->
        email = user.email
      .then -> done()
      .done()

    it 'should get users by email', (done) ->

      Users.search(email)
      .call('read')
      .then (user) ->
        user.id.should.equal(setup.userId)
        user.name.should.equal('user_name')
        user.email.should.equal(email)
        user.pro.should.equal(0)
        user.created_at.should.be.a.Date
      .then -> done()
      .done()

    it 'should fail if you try and get a non-existant user by email', (done) ->

      Users.search(-1)
      .catch (err) ->
        err.message.should.equal 'err_no_row'
        done()
      .done()

  describe ':get', ->

    it 'should get users by id', (done) ->

      Users.get(setup.userId)
      .call('read')
      .then (user) ->
        user.id.should.equal(setup.userId)
        user.name.should.equal('user_name')
      .then -> done()
      .done()

    it 'should fail when user does not exist', (done) ->

      Users.get(-1)
      .catch (err) ->
        err.message.should.equal 'err_no_row'
        done()
      .done()

  describe ':destroy', ->

    it 'should be able to delete users', (done) ->

      Users.get(setup.userId)
      .call('destroy')
      .then ->
        Users.get(setup.userId)
      .catch (err) ->
        err.message.should.equal('err_no_row')
      .then -> done()
      .done()

  describe ':User', ->

    user = null

    beforeEach (done) ->
      Users.get(setup.userId)
      .then (_user) ->
        user = _user
      .then -> done()
      .done()

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
          user.email.should.match(/^user_email/)
          user.password.should.equal('user_password')
          user.created_at.should.be.a.Date
          user.pro.should.equal(0)
        .then -> done()
        .done()

      it 'should throw err when user does not exist', (done) ->

        user = new Users.User(-1)
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

        user = new Users.User(-1)
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

        user = new Users.User(-1)
        user.destroy()
        .catch (err) ->
          err.message.should.equal 'err_no_row'
          done()
        .done()

