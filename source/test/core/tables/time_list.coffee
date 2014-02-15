should  = require('should')
setup   = require('../../setup')
db      = require('../../../core/controllers/database')

describe 'Database', ->

  before (done) ->
    setup()
    .then(setup.createUser)
    .then(setup.createList)
    .then(setup.createTimeList)
    .then -> done()
    .done()

  beforeEach (done) ->
    db.time_list.destroy(setup.listId)
    .then(setup.createTimeList)
    .then -> done()
    .done()

  describe ':time_list', ->

    describe ':create', ->

      beforeEach (done) ->
        db.time_list.destroy(setup.listId)
        .then -> done()
        .done()

      it 'should add timestamps to an existing list', (done) ->

        db.time_list.create(setup._timeList)
        .then -> done()
        .done()

    describe ':read', ->

      it 'should read timestamps for an existing list', (done) ->

        db.time_list.read(setup.listId)
        .then (times) ->
          times.should.eql
            id: setup.listId
            name: 1
            tasks: 1
        .then -> done()
        .done()

    describe ':update', ->

      it 'should update timestamps for an existing list', (done) ->

        db.time_list.update(setup.listId, { name: 2 })
        .then ->
          db.time_list.read(setup.listId, 'name')
        .then (times) ->
          times.name.should.equal(2)
        .then -> done()
        .done()

    describe ':destroy', ->

      it 'should destroy timestamps for an existing list', (done) ->

        db.time_list.destroy(setup.listId)
        .then ->
          db.time_list.read(setup.listId)
        .catch (err) ->
          err.message.should.equal('err_no_row')
          done()
