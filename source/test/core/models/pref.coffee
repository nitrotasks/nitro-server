require('should')
setup = require('../../setup')
Pref  = require('../../../core/models/pref')

describe 'Pref', ->

  pref = null

  before (done) ->
    setup()
    .then(setup.createUser)
    .then -> done()
    .done()

  beforeEach (done) ->
    pref = new Pref(setup.userId)
    pref.destroy()
    .catch (ignore) -> null
    .then(setup.createPref)
    .then -> done()
    .done()

  describe ':create', ->

    beforeEach (done) ->
      pref.destroy()
      .then -> done()
      .done()

    it 'should create a pref', (done) ->

      pref.create
        sort: 0
        night: 1
        language: 'en-nz'
        weekStart: 4
        dateFormat: 'abcdefgh'
        confirmDelete: 6
        moveCompleted: 7
      .then (id) ->
        id.should.equal(setup.userId)
        pref.read()
      .then (pref) ->
        pref.should.eql
          userId: setup.userId
          sort: 0
          night: 1
          language: 'en-nz'
          weekStart: 4
          dateFormat: 'abcdefgh'
          confirmDelete: 6
          moveCompleted: 7
      .then -> done()
      .done()

    it 'should not throw err when column does not exist', (done) ->

      pref.create
        foo: 'bar'
      .then (id) ->
        id.should.equal(setup.userId)
        pref.read()
      .then (pref) ->
        pref.should.eql
          userId: setup.userId
          sort: null
          night: null
          language: null
          weekStart: null
          dateFormat: null
          confirmDelete: null
          moveCompleted: null
      .then -> done()
      .done()

  describe ':exists', ->

    it 'should check a pref exists', (done) ->

      pref.exists()
      .then (success) ->
        success.should.equal(true)
      .then -> done()
      .done()

    it 'should throw err when pref does not exist', (done) ->

      pref.destroy()
      .then ->
        pref.exists()
      .catch (err) ->
        err.message.should.equal('err_no_row')
        done()
      .done()

  describe ':read', ->

    it 'should read a single column', (done) ->

      pref.read('sort')
      .then (data) ->
        data.should.eql
          sort: 0
      .then -> done()
      .done()

    it 'should read multiple columns', (done) ->

      pref.read(['language', 'dateFormat'])
      .then (data) ->
        data.should.eql
          language: 'en-us'
          dateFormat: 'dd/mm/yy'
      .then -> done()
      .done()

    it 'should read all the columns', (done) ->

      pref.read()
      .then (data) ->
        data.should.eql
          userId: setup.prefId
          sort: 0
          night: 0
          language: 'en-us'
          weekStart: 0
          dateFormat: 'dd/mm/yy'
          confirmDelete: 0
          moveCompleted: 0
      .then -> done()
      .done()

    it 'should throw err when pref does not exist', (done) ->

      pref = new Pref(-1)
      pref.read()
      .catch (err) ->
        err.message.should.equal('err_no_row')
        done()
      .done()

  describe ':update', ->

    it 'should update a single column', (done) ->

      pref.update(sort: 2)
      .then ->
        pref.read('sort')
      .then (data) ->
        data.should.eql
          sort: 2
      .then -> done()
      .done()

    it 'should throw err when pref does not exist', (done) ->

      pref = new Pref(-1)
      pref.update(sort: 2)
      .catch (err) ->
        err.message.should.equal('err_no_row')
        done()
      .done()

    it 'should throw err when column does not exist', (done) ->

      pref.update(fake: 'err')
      .catch (err) ->
        err.message.should.eql('err_could_not_update_row')
        done()
      .done()

  describe ':destroy', ->

    it 'should destroy a pref', (done) ->

      pref.destroy()
      .then ->
        pref.read()
      .catch (err) ->
        err.message.should.eql 'err_no_row'
        done()
      .done()

    it 'should throw err when the pref does not exist', (done) ->

      pref = new Pref(-1)
      pref.destroy()
      .catch (err) ->
        err.message.should.equal 'err_no_row'
        done()
      .done()
