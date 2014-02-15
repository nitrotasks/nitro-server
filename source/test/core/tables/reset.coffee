should  = require('should')
setup   = require('../../setup')
db      = require('../../../core/controllers/database')

describe 'Database', ->

  before (done) ->
    setup()
    .then(setup.createUser)
    .then(setup.createReset)
    .then -> done()
    .done()

  beforeEach (done) ->
    db.reset.destroyAll(setup.userId)
    .then(setup.createReset)
    .then -> done()
    .done()

  describe ':reset', ->

    describe ':create', ->

      beforeEach (done) ->
        db.reset.destroyAll(setup.userId)
        .then -> done()
        .done()

      it 'should create a reset token' , (done) ->

        db.reset.create(setup.userId, setup.resetToken)
        .then (token) ->
          token.should.equal(setup.resetToken)
        .then -> done()
        .done()

      it 'should only allow one reset token per user', (done) ->

        db.reset.create(setup.userId, setup.resetTokenm)
        .then ->
          db.reset.create(setup.userId, 'another_token')
        .catch (err) ->
          err.message.should.equal('err_could_not_create_row')
          done()
        .done()

    describe ':read', ->

      it 'should read a reset token', (done) ->

        db.reset.read(setup.resetToken).then (row) ->
          row.userId.should.equal(setup.userId)
          row.token.should.equal(setup.resetToken)
          row.created_at.should.be.an.instanceOf(Date)
        .then -> done()
        .done()

      it 'should throw err when reading a token that does not exist', (done) ->

        db.reset.destroyAll(setup.userId)
        .then ->
          db.reset.read(setup.resetToken)
        .catch (err) ->
          err.message.should.equal 'err_no_row'
          done()
        .done()

    describe ':update', ->

      it 'should not allow a reset token to be changed', (done) ->

        try
          db.reset.update()
        catch e
          e.message.should.equal('err_not_allowed')
          done()

    describe ':destroy', ->

      it 'should destroy a reset token', (done) ->

        db.reset.destroy(setup.resetToken)
        .then -> done()
        .done()

