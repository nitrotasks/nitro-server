should = require('should')
setup  = require('../setup')
Users  = require('../../core/models/user')
Time   = require('../../core/models/time')

describe 'User', ->

  user = null

  before (done) ->
    setup()
    .then(setup.createUser)
    .then -> done()
    .done()

  beforeEach ->
    user = new Users.User(setup.userId)

  describe ':read', ->

    it 'read', (done) ->

      user.read()
      .then (info) ->
        info.id.should.equal(setup.userId)
        info.name.should.equal('user_name')
        info.email.should.equal('user_email')
        info.password.should.equal('user_password')
        info.pro.should.equal(0)
        info.created_at.should.be.a.Date
      .then -> done()
      .done()

    it 'name', (done) ->

      user.read('name')
      .get('name')
      .then (name) ->
        name.should.equal('user_name')
      .then -> done()
      .done()

    it 'email', (done) ->

      user.read('email')
      .get('email')
      .then (email) ->
        email.should.equal('user_email')
      .then -> done()
      .done()

    it 'password', (done) ->

      user.read('password')
      .get('password')
      .then (password) ->
        password.should.equal('user_password')
      .then -> done()
      .done()

  describe ':update', ->

    it 'name', (done) ->

      user.update(name: 'user_name_updated')
      .then ->
        user.read('name').get('name')
      .then (name) ->
        name.should.equal('user_name_updated')
      .then -> done()
      .done()

    it 'email', (done) ->

      user.update(email: 'user_email_updated')
      .then ->
        user.read('email').get('email')
      .then (email) ->
        email.should.equal('user_email_updated')
      .then -> done()
      .done()

    it 'password', (done) ->

      user.update(password: 'user_password_updated')
      .then ->
        user.read('password').get('password')
      .then (password) ->
        password.should.equal('user_password_updated')
      .then -> done()
      .done()


  describe ':<model>', ->

    describe ':create', ->

      listId = null

      it 'list', (done) ->

        user.list.create
          name: 'Things to do'
        .then (id) ->
          id.should.be.a.Number
          listId = id
        .then -> done()
        .done()

      it 'task', (done) ->

        user.task.create
          name: 'Save the world'
          listId: listId
        .then (id) ->
          id.should.be.a.Number
          done()

      it 'pref', (done) ->

        # Storage.add automatically creates a pref for us
        user.pref.destroy()
        .then ->
          user.pref.create
            sort: 1
        .then -> done()
        .done()


    describe ':list<tasks>', ->

      task = null
      list = null

      before (done) ->

        setup.createList()
        .then(setup.createTask)
        .then ->
          user.list.get(setup.listId)
        .then (_list) ->
          list = _list
          user.task.get(setup.taskId)
        .then (_task) ->
          task = _task
          task.removeFromList(list.id)
        .then -> done()
        .done()

      it 'add', (done) ->

        task.addToList(list.id)
        .then -> done()
        .done()

      it 'get', (done) ->

        list.tasks()
        .then (tasks) ->
          tasks.should.eql [ task.id ]
        .then -> done()
        .done()

      it 'remove', (done) ->

        task.removeFromList(list.id)
        .then ->
          list.tasks()
        .then (tasks) ->
          tasks.should.eql []
        .then -> done()
        .done()

    describe ':owns', ->

      before (done) ->

        setup.createList()
        .then(setup.createTask)
        .then -> done()
        .done()

      it 'task - does own', (done) ->

        user.task.owns(setup.taskId)
        .then -> done()
        .done()

      it 'task - does not own', (done) ->

        user.task.owns(-1)
        .catch (err) ->
          err.message.should.equal('err_no_row')
          done()
        .done()

      it 'list - does own', (done) ->

        user.list.owns(setup.listId)
        .then -> done()
        .done()

      it 'list - does not own', (done) ->

        user.list.owns(-1)
        .catch (err) ->
          err.message.should.equal 'err_no_row'
          done()
        .done()


    describe ':read', ->

      task = null
      list = null

      before (done) ->

        Users.destroyAll()
        .then(setup.createUser)
        .then(setup.createList)
        .then(setup.createTask)
        .then ->
          user = new Users.User(setup.userId)
          user.list.get(setup.listId)
        .then (_list) ->
          list = _list
          user.task.get(setup.taskId)
        .then (_task) ->
          task = _task
          task.removeFromList(list.id)
        .then -> done()
        .done()

      it 'task - all rows', (done) ->

        task.read()
        .then (task) ->
          task.should.eql(setup._task)
        .then -> done()
        .done()

      it 'task - partial rows', (done) ->

        task.read(['name', 'completed'])
        .then (task) ->
          task.should.eql
            name: setup._task.name
            completed: setup._task.completed
        .then -> done()
        .done()

      it 'list - all rows', (done) ->

        list.read()
        .then (list) ->
          list.should.eql(setup._list)
        .then -> done()
        .done()

      it 'list - single row', (done) ->

        list.read('name')
        .then (list) ->
          list.should.eql
            name: setup._list.name
        .then -> done()
        .done()

      it 'pref - all rows', (done) ->

        user.pref.read()
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

      it 'pref - single row', (done) ->

        user.pref.read('sort')
        .then (pref) ->
          pref.should.eql
            sort: null
        .then -> done()
        .done()


    describe ':update', ->

      task = null
      list = null

      before (done) ->

        Users.destroyAll()
        .then(setup.createUser)
        .then(setup.createList)
        .then(setup.createTask)
        .then ->
          user = new Users.User(setup.userId)
          user.list.get(setup.listId)
        .then (_list) ->
          list = _list
          user.task.get(setup.taskId)
        .then (_task) ->
          task = _task
        .then -> done()
        .done()

      it 'task - exists', (done) ->

        task.update
          name: 'task_name_updated'
        .then ->
          task.read('name').get('name')
        .then (name) ->
          name.should.equal('task_name_updated')
        .then -> done()
        .done()

      it 'task - does not exist', (done) ->

        (new user.task.constructor.Task(-1)).update
          name: 'Updated Task'
        .catch (err) ->
          err.message.should.eql('err_no_row')
          done()
        .done()

      it 'list - exists', (done) ->

        list.update
          name: 'list_name_updated'
        .then ->
          list.read('name').get('name')
        .then (name) ->
          name.should.equal('list_name_updated')
        .then -> done()
        .done()

      it 'list - does not exist', (done) ->

        (new user.list.constructor.List(-1)).update
          name: 'Updated List'
        .catch (err) ->
          err.message.should.equal('err_no_row')
          done()
        .done()

      it 'pref', (done) ->

        user.pref.update
          moveCompleted: 1
        .then ->
          user.pref.read('moveCompleted').get('moveCompleted')
        .then (moveCompleted) ->
          moveCompleted.should.equal 1
        .then -> done()
        .done()

    describe ':destroy', ->

      task = null
      list = null

      before (done) ->
        user.list.get(setup.listId)
        .then (_list) ->
          list = _list
          user.task.get(setup.taskId)
        .then (_task) ->
          task = _task
        .then -> done()
        .done()

      it 'task - exists', (done) ->

        task.destroy()
        .then ->
          user.task.get(task.id)
        .catch (err) ->
          err.message.should.equal('err_no_row')
          done()
        .done()

      it 'task - does not exist', (done) ->

        (new user.task.constructor.Task(-1)).destroy()
        .catch (err) ->
          err.message.should.eql('err_no_row')
          done()
        .done()

      it 'list - exists', (done) ->

        list.destroy()
        .then ->
          user.list.get(list.id)
        .catch (err) ->
          err.message.should.equal('err_no_row')
          done()
        .done()

      it 'list - does not exist', (done) ->

        (new user.list.constructor.List(-1)).destroy()
        .catch (err) ->
          err.message.should.eql('err_no_row')
          done()
        .done()

      it 'pref', (done) ->

        user.pref.destroy()
        .then ->
          user.pref.read()
        .catch (err) ->
          err.message.should.equal('err_no_row')
          done()
        .done()

    describe ':export', ->

      before (done) ->

        Users.destroyAll()
        .then(setup.createUser)
        .then(setup.createList)
        .then(setup.createTask)
        .then ->
          user = new Users.User(setup.userId)
        .then -> done()
        .done()

      it 'task', (done) ->

        user.task.all()
        .then (tasks) ->
          tasks.should.eql [ setup._task ]
        .then -> done()
        .done()

      it 'list', (done) ->

        user.list.all()
        .then (lists) ->
          lists.should.eql [
            id: setup.listId
            userId: setup.userId
            name: setup._list.name
            tasks: [ setup.taskId ]
          ]
        .then -> done()
        .done()
