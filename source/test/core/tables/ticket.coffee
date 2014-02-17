should  = require('should')
setup   = require('../../setup')
db      = require('../../../core/controllers/database')

describe 'Database', ->

  before (done) ->
    setup()
    .then(setup.createUser)
    .then(setup.createTicket)
    .then -> done()
    .done()

  beforeEach (done) ->
    db.ticket.destroyAll(setup.userId)
    .then(setup.createTicket)
    .then -> done()
    .done()

  describe ':ticket', ->

    describe ':create', ->

      beforeEach (done) ->
        db.ticket.destroyAll(setup.userId)
        .then -> done()
        .done()

      it 'should create a new entry', (done) ->

        db.ticket.create(setup.userId, setup.ticketToken)
        .then -> done()
        .done()

      it 'should create another ticket token', (done) ->

        db.ticket.create(setup.userId, setup.ticketToken)
        .then ->
          db.ticket.create(setup.userId, 'ticket_token_2')
        .then ->
          db.ticket.create(setup.userId, 'ticket_token_3')
        .then ->
          db.ticket.readAll(setup.userId)
        .then (tokens) ->
          tokens.length.should.equal(3)
          tokens[0].token.should.equal('ticket_token')
          tokens[1].token.should.equal('ticket_token_2')
          tokens[2].token.should.equal('ticket_token_3')
        .then -> done()
        .done()

    describe ':read', ->

      it 'should read the date the ticket token was created', (done) ->

        db.ticket.read(setup.userId, setup.ticketToken)
        .then (ticket) ->
          ticket.userId.should.equal(setup.userId)
          ticket.token.should.equal(setup.ticketToken)
          ticket.created_at.should.be.an.instanceOf(Date)
        .then -> done()
        .done()

      it 'should throw err when reading an entry that does not exist', (done) ->

        db.ticket.destroyAll(setup.userId)
        .then ->
          db.ticket.read(setup.userId, setup.ticketToken)
        .catch (err) ->
          err.message.should.equal 'err_no_row'
        .then -> done()
        .done()

    describe ':exists', ->

      it 'should check if a ticket exists', (done) ->

        db.ticket.exists(setup.userId, setup.ticketToken)
        .then (exists) ->
          exists.should.equal(true)
        .then -> done()
        .done()

    describe ':update', ->

      it 'should not allow updating a token', ->

        ( ->
          db.ticket.update(setup.userId, token: 'abc')
        ).should.throw(/cannot update ticket/i)

    describe ':destroy', ->

      it 'should destroy an existing entry', (done) ->

        db.ticket.destroy(setup.userId, setup.ticketToken)
        .then ->
          db.ticket.read(setup.userId, setup.ticketToken)
        .catch (err) ->
          err.message.should.equal('err_no_row')
        .then -> done()
        .done()

      it 'should check if a ticket does not exist', (done) ->

        db.ticket.destroyAll(setup.userId)
        .then ->
          db.ticket.exists(setup.userId, setup.ticketToken)
        .then (exists) ->
          exists.should.equal(false)
        .then -> done()
        .done()

    describe ':destroyAll', (done) ->

      it 'should delete all ticket token', (done) ->

        db.ticket.destroyAll(setup.userId)
        .catch (err) ->
          throw new Error 'could not destroy tokens'
        .then ->
          db.ticket.readAll(setup.userId)
        .catch (err) ->
          err.message.should.equal('err_no_row')
        .then -> done()
        .done()

