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
      sync = new Sync(user)
    .then -> done()
    .done()

  describe ':task_create', ->

    it 'should create a task', (done) ->

      data =
        listId: setup.listId
        name: 'sync_task_name'

      sync.task_create(data)
      .then (id) ->
        user.tasks.get(id).call('read')
      .then (task) ->
        task.id.should.be.a.Number.and.greaterThan(setup.taskId)
        task.userId.should.equal(setup.userId)
        task.listId.should.equal(setup.listId)
        task.name.should.equal('sync_task_name')
      .then -> done()
      .done()

  describe ':list_create', ->

    it 'should create a list', (done) ->

      data =
        name: 'sync_list_name'

      sync.list_create(data)
      .then (id) ->
        user.lists.get(id).call('read')
      .then (list) ->
        list.id.should.be.a.Number.and.greaterThan(setup.listId)
        list.userId.should.equal(setup.userId)
        list.name.should.equal('sync_list_name')
      .then -> done()
      .done()

  describe ':task_update', ->

    taskId = null

    beforeEach (done) ->
      sync.task_create(listId: setup.listId)
      .then (id) ->
        taskId = id
      .then -> done()
      .done()

    it 'should update a task', (done) ->

      data =
        name: 'sync_task_name_updated'

      sync.task_update(taskId, data)
      .then (task) ->
        task.should.eql(data)
        user.tasks.get(taskId).call('read')
      .then (task) ->
        task.name.should.equal('sync_task_name_updated')
      .then -> done()
      .done()

  describe ':list_update', ->

    listId = null

    beforeEach (done) ->
      sync.list_create(name: 'sync_list_update')
      .then (id) ->
        listId = id
      .then -> done()
      .done()

    it 'should update a list', (done) ->

      data =
        name: 'sync_list_name_updated'

      sync.list_update(listId, data)
      .then (list) ->
        list.should.eql(data)
        user.lists.get(listId).call('read')
      .then (list) ->
        list.name.should.equal('sync_list_name_updated')
      .then -> done()
      .done()

  describe ':pref_update', ->

    it 'should update a pref', (done) ->

      data =
        sort: 1

      sync.pref_update(data)
      .then (pref) ->
        pref.should.eql(data)
        user.pref.read()
      .then (pref) ->
        pref.sort.should.equal(1)
      .then -> done()
      .done()

  describe ':task_destroy', ->

    it 'should destroy a task', (done) ->

      sync.task_destroy(setup.taskId)
      .then (success) ->
        success.should.equal(true)
      .then -> done()
      .done()

  describe ':list_destroy', ->

    it 'should destroy a list', (done) ->

      sync.list_destroy(setup.listId)
      .then (success) ->
        success.should.equal(true)
      .then -> done()
      .done()


