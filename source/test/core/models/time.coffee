require('should')
Time  = require('../../../core/models/time')
setup = require('../../setup')

describe 'Time', ->

  before (done) ->
    setup()
    .then(setup.createUser)
    .then(setup.createList)
    .then(setup.createTask)
    .then -> done()
    .done()

  describe ':now', ->

    it 'should return the current time in seconds', ->

      now = Time.now()
      now.should.be.a.Number
      now.toString().length.should.equal(10)

  describe ':offset', ->

    it 'should calculate offset for a single time', ->

      Time.offset(100, 200).should.equal 300
      Time.offset(-100, 200).should.equal 100
      Time.offset(0, 200).should.eql 200

    it 'should calculate the offset for multiple times', ->

      Time.offset -50,
        name: 100
        list: 200
        id: 300
      .should.eql
        name: 50
        list: 150
        id: 250

  describe ':task', ->

    time = Time.task

    beforeEach (done) ->
      time.destroy(setup.taskId)
      .then ->
        time.create(setup.taskId, 100)
      .then -> done()
      .done()

    describe ':create', ->

      beforeEach (done) ->
        time.destroy(setup.taskId)
        .then -> done()
        .done()

      it 'should create a new time', (done) ->

        time.create(setup.taskId, Time.now())
        .then (id) ->
          id.should.equal(setup.taskId)
        .then -> done()
        .done()

    describe ':read', ->

      it 'should read an existing time', (done) ->

        time.read(setup.taskId)
        .then (times) ->
          times.should.eql
            id: setup.taskId
            listId: 100
            name: 100
            notes: 100
            priority: 100
            completed: 100
            date: 100
        .then -> done()
        .done()

    describe ':update', ->

      it 'should update an existing time', (done) ->

        data =
          name: 200
          notes: 200

        time.update(setup.taskId, data)
        .then ->
          time.read(setup.taskId)
        .then (times) ->
          times.should.eql
            id: setup.taskId
            listId: 100
            name: 200
            notes: 200
            priority: 100
            completed: 100
            date: 100
        .then -> done()
        .done()

    describe ':destroy', ->

      it 'should destroy an existing time', (done) ->

        time.destroy(setup.taskId)
        .then (success) ->
          success.should.equal(true)
        .then ->
          time.read(setup.taskId)
        .catch (err) ->
          err.message.should.equal('err_no_row')
          done()
        .done()

    describe ':checkSingle', ->

      it 'a more higher time should pass', (done) ->

        time.checkSingle(setup.taskId, 200)
        .then (pass) ->
          pass.should.equal(true)
        .then -> done()
        .done()

      it 'a lower time should fail', (done) ->

        time.checkSingle(setup.taskId, 50)
        .catch (err) ->
          err.message.should.equal('err_old_time')
          done()
        .done()

      it 'an equal time should pass', (done) ->

        time.checkSingle(setup.taskId, 100)
        .then (pass) ->
          pass.should.equal(true)
        .then -> done()
        .done()

      it 'only needs to be lower than a single to fail', (done) ->

        time.update(setup.taskId, date: 110)
        .then ->
          time.checkSingle(setup.taskId, 105)
        .catch (err) ->
          err.message.should.equal('err_old_time')
          done()
        .done()

    describe ':checkMultiple', ->

      it 'should check multiple values', (done) ->

        data =
          listId: 3
          name: 'task_name_updated'
          notes: 'task_notes_updated'
          priority: 3
          completed: 111
          date: 111

        time.checkMultiple setup.taskId, data,
          listId: 110
          name: 110
          notes: 110
          priority: 100
          completed: 90
          date: 90
        .then (times) ->
          times.should.eql
            listId: 110
            name: 110
            notes: 110
            priority: 100
        .then -> done()
        .done()

      it 'should throw err when all values are old', (done) ->

        data =
          listId: 3
          name: 'task_name_updated'
          notes: 'task_notes_updated'
          priority: 3
          completed: 111
          date: 111

        time.checkMultiple setup.taskId, data,
          listId: 90
          name: 90
          notes: 90
          priority: 90
          completed: 90
          date: 90
        .catch (err) ->
          err.message.should.equal 'err_old_time'
          done()
        .done()

    describe ':updateMultiple', ->

      it 'should update multiple values', (done) ->

        data =
          name: 'task_name_updated'

        time.updateMultiple setup.taskId, data,
          name: 200
        .then (times) ->
          times.should.eql
            name: 200
          time.read(setup.taskId)
        .then (times) ->
          times.should.eql
            id: setup.taskId
            listId: 100
            name: 200
            notes: 100
            priority: 100
            completed: 100
            date: 100
        .then -> done()
        .done()


