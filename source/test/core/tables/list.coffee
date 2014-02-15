should  = require('should')
setup   = require('../../setup')
db      = require('../../../core/controllers/database')

describe 'Database', ->

  before (done) ->
    setup()
    .then(setup.createUser)
    .then(setup.createList)
    .then -> done()
    .done()

  beforeEach (done) ->
    db.list.destroy(setup.listId)
    .then(setup.createList)
    .then -> done()
    .done()

  describe ':list', ->

    describe ':create', ->

      beforeEach (done) ->
        db.list.destroy(setup.listId)
        .then -> done()
        .done()

      it 'should create a new list', (done) ->

        id = null

        db.list.create(setup._list)
        .then (_id) ->
          id =_id
          id.should.be.a.Number
          db.list.read(id)
        .then (list) ->
          list.should.eql
            id: id
            userId: setup.userId
            name: 'list_name'
        .then -> done()
        .done()

    describe ':read', ->

      it 'should read an existing list', (done) ->

        db.list.read(setup.listId)
        .then (list) ->
          list.should.eql
            id: setup.listId
            userId: setup.userId
            name: 'list_name'
        .then -> done()
        .done()

    describe ':update', ->

      it 'should update an existing list', (done) ->

        db.list.update setup.listId,
          name: 'list_name_updated'
        .then ->
          db.list.read(setup.listId, 'name')
        .then (list) ->
          list.name.should.equal('list_name_updated')
        .then -> done()
        .done()

    describe ':destroy', ->

      it 'should destroy an existing list', (done) ->

        db.list.destroy(setup.listId)
        .then ->
          db.list.read(setup.listId)
        .catch (err) ->
          err.message.should.equal('err_no_row')
          done()
        .done()

