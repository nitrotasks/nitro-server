# Switch xType into debug mode
global.DEBUG = true

Socket  = require '../app/controllers/socket'
Storage = require '../app/controllers/storage'
Auth    = require '../app/controllers/auth'
should  = require 'should'
Jandal  = require 'jandal'
setup   = require './setup'
mockjs  = require './mockjs'
client  = require './mock_client'

describe '[Socket]', ->

  make =

    _list:
      id: 0
      name: 'list'
      tasks: []

    _task:
      id: 0
      name: 'task'
      listId: 'inbox'
      date: 0
      completed: 0
      notes: ''
      priority: 0

    _model: (parent, child) ->
      for key, value of parent
        child[key] ?= value
      id = child.id
      delete child.id
      child.id = id
      return child

    task: (info) ->
      make._model(make._task, info)

    list: (info) ->
      make._model(make._list, info)

  socket = null

  user =
    id: null
    token: null
    name: 'Fred'
    email: 'fred@gmail.com'
    pass: 'xkcd'
    pro: 0

  before setup

  beforeEach ->
    Socket.init(null, mockjs)
    socket = mockjs.createSocket()
    client.socket = socket

  afterEach ->
    socket.end()
    client.setId 1

  expect = (fn) ->
    socket.once 'message', (response) ->
      res = Jandal::parse(response)
      fn res.arg1, res.arg2, res.arg3


  describe '[setup]', ->

    it 'should create a new user', (done) ->

      Auth.register(user.name, user.email, user.pass)
      .then (token) ->
        Auth.verifyRegistration(token)
      .then ->
        Auth.login(user.email, user.pass)
      .then ([id, token]) ->
        user.id = id
        user.token = token
        done()
      .fail (err) ->
        console.log err

  describe '[auth]', ->

    it 'should try to auth', (done) ->

      socket.on 'close', ->
        socket.open.should.equal false
        done()

      client.user.auth(20, "token")

    it 'SLOW should be kicked after 3 seconds', (done) ->

      @timeout 3200
      start = Date.now()

      socket.on 'close', ->
        diff = Date.now() - start
        diff.should.be.approximately(3000, 10)
        socket.open.should.equal false
        done()

    it 'should login via sockets', (done) ->

      expect (err, val) ->
        should.equal null, err
        val.should.be.true
        done()

      client.user.auth(user.id, user.token)


  describe '[methods]', ->

    list = {}
    task = {}

    beforeEach (done) ->

      expect (err, val) ->
        should.equal null, err
        val.should.be.true
        done()

      client.user.auth(user.id, user.token)

    it 'should get user info', (done) ->

      expect (err, info) ->
        should.equal null, err
        info.should.eql
          name: user.name
          email: user.email
          pro: user.pro
        done()

      client.user.info()

    it 'should create a list', (done) ->

      expect (err, id) ->
        should.equal null, err
        id.should.be.a.Number
        list.id = id
        done()

      list = make.list
        id: 0
        name: 'Inbox'

      client.list.create list

    it 'should create a task', (done) ->

      expect (err, id) ->
        should.equal null, err
        id.should.be.a.Number
        task.id = id
        done()

      task = make.task
        id: -2
        name: 'something'
        listId: list.id

      client.task.create task

    it 'should fetch user data', (done) ->

      expect (err, info) ->
        should.equal null, err
        info.should.eql [ task ]
        done()

      client.task.fetch()

    it 'should destroy user data', (done) ->

      expect (err) ->
        should.equal null, err

        expect (err, info) ->
          should.equal null, err
          info.should.eql []
          done()

        client.task.fetch()

      client.task.destroy id: task.id


    describe '[broadcast]', ->

      # Create a second socket called other
      other = null

      beforeEach (done) ->
        other = mockjs.createSocket()
        client.socket = other

        other.on 'message', (message) ->
          if message is 'Jandal.fn_2(null,true)'
            client.socket = socket
            done()

        client.user.auth(user.id, user.token)


      afterEach ->
        other.end()


      testBroadcast = (done, event, fn) ->

        client.socket = null
        client.callback = false

        client.socket = socket
        client.callback = true

        other.once 'message', (response) ->
          res = Jandal::parse(response)
          event.should.equal res.namespace + '.' + res.event
          fn res.arg1, res.arg2, res.arg3
          done()


      it 'should create a task', (done) ->

        task = make.task
          id: 1
          listId: list.id
          name: 'A brand new task'

        testBroadcast done, 'task.create', (_task) ->
          task.id = _task.id
          _task.should.eql task

        client.task.create task

      it 'should create a list', (done) ->

        list = make.list
          id: 1
          name: 'A brand new list'

        testBroadcast done, 'list.create', (_list) ->
          list.id = _list.id
          list.should.eql list

        client.list.create list

      it 'should update a task', (done) ->

        testBroadcast done, 'task.update', (_task) ->
          _task.should.eql
            id: task.id
            name: 'An updated task'
            priority: 2

        client.task.update
          id: task.id
          name: 'An updated task'
          priority: 2

      it 'should update a list', (done) ->

        testBroadcast done, 'list.update', (_list) ->
          _list.should.eql
            id: list.id
            name: 'An updated list'

        client.list.update
          id: list.id
          name: 'An updated list'

      it 'should update a pref', (done) ->

        testBroadcast done, 'pref.update', (pref) ->
          pref.should.eql
            sort: 1
            dateFormat: 'yy/mm/dd'

        client.pref.update
          sort: 1
          dateFormat: 'yy/mm/dd'

      it 'should update a pref again', (done) ->

        testBroadcast done, 'pref.update', (pref) ->
          pref.should.eql
            language: 'en-us'

        client.pref.update
          language: 'en-us'

      it 'should destroy a task', (done) ->

        testBroadcast done, 'task.destroy', (task) ->
          task.should.eql
            id: task.id

        client.task.destroy
          id: task.id

      it 'should destroy a list', (done) ->

        testBroadcast done, 'list.destroy', (list) ->
          list.should.eql
            id: list.id

        client.list.destroy
          id: list.id

###
    describe '[queue]', ->

      CREATE = 0
      UPDATE = 1
      DESTROY = 2

      beforeEach (done) ->
        Storage.get(user.id).then (user) ->
          user.wipe()
          done()

      test = (input, output, done) ->

        # Fix input
        for id, event of input.list
          if event[0] is 0 then event[1] = make.list event[1]
        for id, event of input.task
          if event[0] is 0 then event[1] = make.task event[1]

        # Fix output
        output.list.map (item) -> make.list item
        output.task.map (item) -> make.task item

        socket.on 'message', (message) ->
          # 17 = "Jandal.fn_2(null,".length
          # -1 = ")"
          {list, task, pref} = JSON.parse(message[17...-1])
          list.should.eql output.list
          task.should.eql output.task
          done()
        client.queue.sync input


      it 'create lists and tasks simultaneously', (done) ->

        now = Date.now()

        input =

          list:
            c20: [CREATE, {
              id: 'c20', name: 'list 1', tasks: ['c12', 'c13'] }, now]
            c33: [CREATE, {
              id: 'c33', name: 'list 2', tasks: ['c14', 'c15'] }, now]

          task:
            c12: [CREATE, {
              id: 'c12', name: 'task 1', listId: 'c20' }, now]
            c13: [CREATE, {
              id: 'c13', name: 'task 2', listId: 'c20' }, now]
            c14: [CREATE, {
              id: 'c14', name: 'task 3', listId: 'c33' }, now]
            c15: [CREATE, {
              id: 'c15', name: 'task 4', listId: 'c33' }, now]

        output =

          list: [
            id: 's0'
            name: 'list 1',
            tasks: ['s0', 's1']
          ,
            id: 's1'
            name: 'list 2'
            tasks: ['s2', 's3']
          ]

          task: [
            id: 's0'
            name: 'task 1'
            listId: 's0'
          ,
            id: 's1'
            name: 'task 2'
            listId: 's0'
          ,
            id: 's2'
            name: 'task 3'
            listId: 's1'
          ,
            id: 's3'
            name: 'task 4'
            listId: 's1'
          ]

        test input, output, done



      it 'update existing items', (done) ->

        client.list.create make.list id: 'c0', name: 'List 1'
        client.task.create make.task id: 'c1', name: 'Task 1', listId: 's0'
        client.task.create make.task id: 'c2', name: 'Task 2', listId: 's0'
        client.task.create make.task id: 'c3', name: 'Task 3', listId: 's0'

        now = Date.now() + 100

        input =

          task:
            s0: [ UPDATE,
              { id: 's0', name: 'Task 1 - Updated', listId: 'c1' },
              { name: now, listId: now }]
            s1: [ UPDATE,
              { id: 's1', name: 'Task 2 - Updated' },
              { name: now }]
            s2: [ UPDATE,
              { id: 's2', name: 'Task 3 - Updated', listId: 'c1' },
              { name: now, listId: now }]

          list:
            s0: [ UPDATE,
              { id: 's0', name: 'List 1 - Updated' },
              { name: now }]
            c1: [CREATE, { id: 'c1', name: 'List 2' }, now]


        output =

          list: [
            id: 's0'
            name: 'List 1 - Updated'
            tasks: ['s1']
          ,
            id: 's1'
            name: 'List 2'
            tasks: ['s0', 's2']
          ]

          task: [
            id: 's0'
            name: 'Task 1 - Updated'
            listId: 's1'
          ,
            id: 's1'
            name: 'Task 2 - Updated'
            listId: 's0'
          ,
            id: 's2'
            name: 'Task 3 - Updated'
            listId: 's1'
          ]

        test input, output, done


      it 'destroy existing tasks', (done) ->

        now = Date.now() + 10

        client.list.create make.list id: 'c0', name: 'List 1'
        client.task.create make.task id: 'c1', name: 'Task 1', listId: 's0'
        client.task.create make.task id: 'c2', name: 'Task 2', listId: 's0'
        client.task.create make.task id: 'c3', name: 'Task 3', listId: 's0'

        input =

          task:
            s0: [DESTROY, {id: 's0'}, now]
            s1: [DESTROY, {id: 's1'}, now]
            s2: [DESTROY, {id: 's2'}, now]
            c1: [CREATE, { id: 'c1', name: 'Task 4', listId: 'c1' }, now]

          list:
            s0: [UPDATE,
              { id: 's0', name: 'List 1 - Updated' },
              { name: now }]
            c1: [CREATE, {name: 'List 2'}, now]

        output =

          list: [
            name: 'List 1 - Updated'
            tasks: []
            id: 's0'
          ,
            name: 'List 2'
            tasks: [ 's3' ]
            id: 's1'
          ]

          task: [
            id: 's3'
            name: 'Task 4'
            listId: 's1'
          ]

        test input, output, done
###
