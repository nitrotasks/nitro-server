require('should')
setup = require('../../setup')
Prefs = require('../../../core/models/pref')

describe 'Pref', ->

  prefs = null

  before (done) ->
    setup()
    .then(setup.createUser)
    .then(setup.createPref)
    .then -> done()
    .done()

  beforeEach (done) ->
    prefs = new Prefs(setup.userId)
    prefs.destroy()
    .then(setup.createPref)
    .then -> done()
    .done()

  describe ':create', ->

    beforeEach (done) ->
      prefs.destroy()
      .then -> done()
      .done()

    it 'should create a pref', (done) ->

      prefs.create
        sort: 0
        night: 1
        language: 'en-nz'
        weekStart: 4
        dateFormat: 'abcdefgh'
        confirmDelete: 6
        moveCompleted: 7
      .then (id) ->
        id.should.equal(setup.userId)
        prefs.get(id).read()
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

      prefs.create
        foo: 'bar'
      .then (id) ->
        id.should.equal(setup.userId)
        prefs.get(id).read()
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

  describe ':get', ->

    it 'should get a pref', ->

      pref = prefs.get(setup.prefId)
      pref.should.be.an.instanceOf(Prefs.Pref)
      pref.id.should.equal(setup.prefId)

    it 'should not throw err if pref does not exist', ->

      pref = prefs.get(-1)
      pref.should.be.an.instanceOf(Prefs.Pref)
      pref.id.should.equal(-1)

  describe ':owns', ->

    it 'should own a pref', (done) ->

      prefs.owns(setup.prefId)
      .then (success) ->
        success.should.equal(true)
      .then -> done()
      .done()

    it 'should throw err when pref does not exist', (done) ->

      prefs.destroy()
      .then ->
        prefs.owns(setup.prefId)
      .catch (err) ->
        err.message.should.equal('err_no_row')
        done()
      .done()

    it 'should throw err when user does not own pref', (done) ->

      setup.createUser()
      .then(setup.createPref)
      .then (id) ->
        prefs.owns(id)
      .catch (err) ->
        err.message.should.equal('err_does_not_own')
        done()
      .done()

  describe ':all', ->

    it 'should get all users prefs', (done) ->

      prefs.all().then (prefs) ->
        prefs.should.eql
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

    it 'should throw err if user does not have any prefs', (done) ->

      prefs.destroy()
      .bind(prefs)
      .then(prefs.all)
      .catch (err) ->
        err.message.should.equal('err_no_row')
        done()
      .done()

  describe ':destroy', ->

    it 'should destroy all prefs owned by a user', (done) ->

      prefs.destroy()
      .bind(prefs)
      .then(prefs.all)
      .catch (err) ->
        err.message.should.equal('err_no_row')
        done()
      .done()

    it 'should throw err if user does not have any prefs', (done) ->

      prefs.destroy()
      .bind(prefs)
      .then(prefs.destroy)
      .then(prefs.all)
      .catch (err) ->
        err.message.should.equal('err_no_row')
        done()
      .done()

  describe ':Pref', ->

    pref = null

    beforeEach ->
      pref = prefs.get(setup.prefId)

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

        pref = new Prefs.Pref(-1)
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

        pref = new Prefs.Pref(-1)
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

        pref = new Prefs.Pref(-1)
        pref.destroy()
        .catch (err) ->
          err.message.should.equal 'err_no_row'
          done()
        .done()
