should  = require('should')
setup   = require('../../setup')
db      = require('../../../core/controllers/database')

describe 'Database', ->

  before (done) ->
    setup()
    .then(setup.createUser)
    .then(setup.createTimePref)
    .then -> done()
    .done()

  beforeEach (done) ->
    db.time_pref.destroy(setup.userId)
    .then(setup.createTimePRef)
    .then -> done()
    .done()

  describe ':time_pref', ->

    describe ':create', ->

      beforeEach (done) ->
        db.time_pref.destroy(setup.userId)
        .then -> done()
        .done()

      it 'should add timestamps to an existing pref', (done) ->

        db.time_pref.create(setup._timePref)
        .then -> done()
        .done()

    describe ':read', ->

      it 'should read timestamps for an existing pref', (done) ->

        db.time_pref.read(setup.userId)
        .then (times) ->
          times.should.eql
            id: setup.userId
            sort: 1
            night: 1
            language: 1
            weekStart: 1
            dateFormat: 1
            confirmDelete: 1
            moveCompleted: 1
        .then -> done()
        .done()

    describe ':update', ->

      it 'should update timestamps for an existing pref', (done) ->

        db.time_pref.update setup.userId,
          sort: 3
          night: 3
        .then ->
          db.time_pref.read(setup.userId, ['sort', 'night'])
        .then (times) ->
          times.sort.should.equal(3)
          times.night.should.equal(3)
        .then -> done()
        .done()

    describe ':destroy', ->

      it 'should destroy timestamps for an existing pref', (done) ->

        db.time_pref.destroy(setup.userId)
        .then ->
          db.time_pref.read(setup.userId)
        .catch (err) ->
          err.message.should.equal('err_no_row')
          done()
