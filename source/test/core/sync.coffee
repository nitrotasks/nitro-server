should  = require 'should'
Promise = require 'bluebird'
setup   = require '../setup'
Sync    = require '../../core/controllers/sync'
Users   = require '../../core/models/user'
Time    = require '../../core/models/time'

describe 'Sync', ->

  user = null
  sync = null

  before (done) ->
    setup()
    .then(setup.createUser)
    .then(setup.createList)
    .then(setup.createTask)
    .then -> done()
    .done()

  beforeEach (done) ->
    Users.get(setup.userId)
    .then (_user) ->
      user = _user
      sync = new Sync(user, 'sync-test')
    .then -> done()
    .done()

  describe ':task', ->

    describe ':create', ->

      it 'should create a task', (done) ->

        data =
          listId: setup.listId
          name: 'sync_task_name'

        sync.task.create(data)
        .then (task) ->
          task.id.should.be.a.Number.and.greaterThan(setup.taskId)
          task.userId.should.equal(setup.userId)
          task.listId.should.equal(setup.listId)
          task.name.should.equal('sync_task_name')
        .then -> done()
        .done()

    describe ':update', ->

      taskId = null

      beforeEach (done) ->
        sync.task.create(listId: setup.listId)
        .then (task) ->
          taskId = task.id
        .then -> done()
        .done()

      it 'should update a task', (done) ->

        data =
          name: 'sync_task_name_updated'

        sync.task.update(taskId, data)
        .then (task) ->
          task.should.have.keys([
            'name', 'notes', 'completed', 'priority', 'date',
            'listId', 'userId', 'id'
          ])
          task.name.should.equal('sync_task_name_updated')
          task.listId.should.equal(setup.listId)
          task.userId.should.equal(setup.userId)
          user.task.get(taskId).call('read')
        .then (task) ->
          task.name.should.equal('sync_task_name_updated')
        .then -> done()
        .done()

    describe ':destroy', ->

      it 'should destroy a task', (done) ->

        sync.task.destroy(setup.taskId)
        .then (success) ->
          success.should.equal(true)
        .then -> done()
        .done()


  describe ':list', ->

    describe ':create', ->

      it 'should create a list', (done) ->

        data =
          name: 'sync_list_name'

        sync.list.create(data)
        .then (list) ->
          list.should.have.keys('id', 'userId', 'name')
          list.id.should.be.a.Number.and.greaterThan(setup.listId)
          list.userId.should.equal(setup.userId)
          list.name.should.equal('sync_list_name')
        .then -> done()
        .done()

    describe ':update', ->

      listId = null

      beforeEach (done) ->
        sync.list.create(name: 'sync_list_update')
        .then (list) ->
          listId = list.id
        .then -> done()
        .done()

      it 'should update a list', (done) ->

        data =
          name: 'sync_list_name_updated'

        sync.list.update(listId, data)
        .then (list) ->
          list.should.have.keys('id', 'userId', 'name')
          list.name.should.equal('sync_list_name_updated')
          user.list.get(listId).call('read')
        .then (list) ->
          list.name.should.equal('sync_list_name_updated')
        .then -> done()
        .done()


    describe ':destroy', ->

      it 'should destroy a list', (done) ->

        sync.list.destroy(setup.listId)
        .then (success) ->
          success.should.equal(true)
        .then -> done()
        .done()


  describe ':pref', ->

    describe ':update', ->

      it 'should update a pref', (done) ->

        data =
          sort: 1

        sync.pref.update(null, data)
        .then (pref) ->
          pref.should.have.keys([
            'userId', 'sort', 'night', 'language', 'weekStart',
            'dateFormat', 'moveCompleted', 'confirmDelete'
          ])
          pref.sort.should.equal(1)
          user.pref.read()
        .then (pref) ->
          pref.sort.should.equal(1)
        .then -> done()
        .done()

