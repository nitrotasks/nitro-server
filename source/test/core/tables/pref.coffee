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
    db.pref.destroy(setup.userId)
    .then(setup.createPref)
    .then -> done()
    .done()

  describe ':pref', ->

    describe ':create', ->

      beforeEach (done) ->
        db.pref.destroy(setup.prefId)
        .then -> done()
        .done()

      it 'should create a new pref', (done) ->

        db.pref.create(setup._pref)
        .then (id) ->
          id.should.equal(setup.userId)
          db.pref.read(setup.prefId)
        .then (pref) ->
          pref.should.eql
            userId: setup.userId
            sort: 0
            night: 0
            language: 'en-us'
            weekStart: 0
            dateFormat: 'dd/mm/yy'
            confirmDelete: 0
            moveCompleted: 0
        .then -> done()
        .done()

      it 'should only allow one pref per user', (done) ->

        db.pref.create(setup._pref)
        .then ->
          db.pref.create(setup._pref)
        .catch (err) ->
          err.message.should.equal('err_could_not_create_row')
          done()
        .done()

    describe ':read', ->

      it 'should read from a pref', (done) ->

        db.pref.read(setup.prefId)
        .then (info) ->
          info.should.eql
            userId: setup.userId
            sort: 0
            night: 0
            language: 'en-us'
            weekStart: 0
            dateFormat: 'dd/mm/yy'
            confirmDelete: 0
            moveCompleted: 0
        .then -> done()
        .done()

    describe ':update', ->

      it 'should update a pref', (done) ->

        db.pref.update setup.prefId,
          sort: 2
        .then ->
          db.pref.read(setup.prefId, 'sort')
        .then (pref) ->
          pref.sort.should.equal(2)
        .then -> done()
        .done()

    describe ':destroy', ->

      it 'should destroy a pref', (done) ->

        db.pref.destroy(setup.prefId)
        .then ->
          db.pref.read(setup.prefId)
        .catch (err) ->
          err.message.should.equal('err_no_row')
          done()
        .done()
