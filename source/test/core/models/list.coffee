require('should')
setup = require('../../setup')
Tasks = require('../../../core/models/task')
Lists = require('../../../core/models/list')

describe 'List', ->

  lists = null

  before (done) ->
    setup()
    .then(setup.createUser)
    .then(setup.createList)
    .then -> done()
    .done()

  beforeEach (done) ->
    lists = new Lists(setup.userId)
    lists.destroy()
    .then(setup.createList)
    .then(setup.createTask)
    .then -> done()
    .done()

  describe ':create', ->

    it 'should create a list', (done) ->

      id = null

      lists.create
        name: 'list_name'
      .then (_id) ->
        id = _id
        id.should.be.a.Number
        lists.get(id).call('read')
      .then (list) ->
        list.should.eql
          id: id
          userId: setup.userId
          name: 'list_name'
      .then -> done()
      .done()

    it 'should not throw err when column does not exist', (done) ->

      id = null

      lists.create
        foo: 'bar'
        name: 'list_name'
      .then (_id) ->
        id = _id
        id.should.be.a.Number
        lists.get(id).call('read')
      .then (list) ->
        list.should.eql
          id: id
          userId: setup.userId
          name: 'list_name'
      .then -> done()
      .done()

  describe ':get', ->

    it 'should get a list', (done) ->

      lists.get(setup.listId)
      .then (list) ->
        list.should.be.an.instanceOf(Lists.List)
        list.id.should.equal(setup.listId)
      .then -> done()
      .done()

    it 'should throw err if list does not exist', (done) ->

      lists.get(-1)
      .catch (err) ->
        err.message.should.equal('err_no_row')
        done()
      .done()

  describe ':owns', ->

    it 'should own a list', (done) ->

      lists.owns(setup.listId)
      .then (success) ->
        success.should.equal(true)
      .then -> done()
      .done()

    it 'should throw err when list does not exist', (done) ->

      lists.owns(-1)
      .catch (err) ->
        err.message.should.equal('err_no_row')
        done()
      .done()

    it 'should throw err when user does not own list', (done) ->

      setup.createUser()
      .then(setup.createList)
      .then (id) ->
        lists.owns(id)
      .catch (err) ->
        err.message.should.equal('err_no_row')
        done()
      .done()

  describe ':all', ->

    it 'should get all users lists', (done) ->

      lists.all().then (lists) ->
        lists.should.eql [
          id: setup.listId
          userId: setup.userId
          name: 'list_name'
          tasks: [ setup.taskId ]
        ]
      .then -> done()
      .done()

    it 'should not throw err if user does not have any lists', (done) ->

      lists.destroy()
      .bind(lists)
      .then(lists.all)
      .then (lists) ->
        lists.should.eql []
      .then -> done()
      .done()

  describe ':destroy', ->

    it 'should destroy all lists owned by a user', (done) ->

      lists.destroy()
      .bind(lists)
      .then(lists.all)
      .then (lists) ->
        lists.should.eql []
      .then -> done()
      .done()

    it 'should not throw err if user does not have any lists', (done) ->

      lists.destroy()
      .bind(lists)
      .then(lists.destroy)
      .then(lists.all)
      .then (lists) ->
        lists.should.eql []
      .then -> done()
      .done()

  describe ':List', ->

    list = null

    beforeEach (done) ->
      lists.get(setup.listId)
      .then (_list) ->
        list = _list
      .then -> done()
      .done()

    describe ':read', ->

      it 'should read a single column', (done) ->

        list.read('name')
        .then (data) ->
          data.should.eql
            name: 'list_name'
        .then -> done()
        .done()

      it 'should read multiple columns', (done) ->

        list.read(['id', 'name'])
        .then (data) ->
          data.should.eql
            id: setup.listId
            name: 'list_name'
        .then -> done()
        .done()

      it 'should read all the columns', (done) ->

        list.read()
        .then (data) ->
          data.should.eql
            id: setup.listId
            userId: setup.userId
            name: 'list_name'
        .then -> done()
        .done()

      it 'should throw err when list does not exist', (done) ->

        list = new Lists.List(-1)
        list.read()
        .catch (err) ->
          err.message.should.equal('err_no_row')
          done()
        .done()

    describe ':update', ->

      it 'should update a single column', (done) ->

        list.update(name: 'list_name_updated')
        .then ->
          list.read('name')
        .then (data) ->
          data.should.eql
            name: 'list_name_updated'
        .then -> done()
        .done()

      it 'should throw err when list does not exist', (done) ->

        list = new Lists.List(-1)
        list.update(name: 'list_name_updated')
        .catch (err) ->
          err.message.should.equal('err_no_row')
          done()
        .done()

      it 'should throw err when column does not exist', (done) ->

        list.update(fake: 'err')
        .catch (err) ->
          err.message.should.eql('err_could_not_update_row')
          done()
        .done()

    describe ':destroy', ->

      it 'should destroy a list', (done) ->

        list.destroy()
        .then ->
          list.read()
        .catch (err) ->
          err.message.should.eql 'err_no_row'
          done()
        .done()

      it 'should throw err when the list does not exist', (done) ->

        list = new Lists.List(-1)
        list.destroy()
        .catch (err) ->
          err.message.should.equal 'err_no_row'
          done()
        .done()

    describe ':tasks', ->

      it 'should get the tasks in the list', (done) ->

        list.tasks()
        .then (tasks) ->
          tasks.should.eql [ setup.taskId ]
        .then -> done()
        .done()

      it 'should not throw err if list has not tasks', (done) ->

        (new Tasks.Task(setup.taskId)).destroy()
        .bind(list)
        .then(list.tasks)
        .then (tasks) ->
          tasks.should.eql []
        .then -> done()
        .done()
