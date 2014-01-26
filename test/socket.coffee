# Switch xType into debug mode
global.DEBUG = true

Socket  = require '../app/controllers/socket'
Storage = require '../app/controllers/storage'
Auth    = require '../app/controllers/auth'
should  = require 'should'
setup   = require './setup'
mockjs  = require './mockjs'
client  = require './mock_client'

describe '[Socket]', ->

  make =

    _list:
      id: 'c0'
      name: 'list'
      tasks: []

    _task:
      id: 'c0'
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

  before setup

  beforeEach ->
    Socket.init(null, mockjs)
    socket = mockjs.createSocket()
    client.socket = socket

  afterEach ->
    socket.end()
    client.setId 1

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

###
  describe '[auth]', ->

    it 'should try to auth', (done) ->
      socket.on 'close', ->
        socket.open.should.equal false
        done()
      client.user.auth(20, "token")

    it 'should be kicked after 3 seconds', (done) ->
      @timeout 3200
      start = Date.now()
      socket.on 'close', ->
        diff = Date.now() - start
        diff.should.be.approximately(3000, 10)
        socket.open.should.equal false
        done()

    it 'should login via sockets', (done) ->
      socket.on 'message', (message) ->
        message.should.equal 'Jandal.fn_1(null,true)'
        socket.end()
        done()
      client.user.auth(user.id, user.token)


  describe '[methods]', ->

    beforeEach (done) ->
      client.user.auth(user.id, user.token)
      socket.on 'message', (message) ->
        if message is 'Jandal.fn_1(null,true)'then done()

    it 'should get user info', (done) ->
      socket.on 'message', (message) ->
        message.should.equal 'Jandal.fn_2(null,{"name":"Fred","email":"fred@gmail.com","pro":0})'
        done()
      client.user.info()

    it 'should create the inbox list', (done) ->
      socket.on 'message', (message) ->
        message.should.equal 'Jandal.fn_2(null,"inbox")'
        done()
      client.list.create make.list
        id: 'inbox'
        name: 'Inbox'

    it 'should only create the inbox list once', (done) ->
      socket.on 'message', (message) ->
        message.should.equal 'Jandal.fn_2(true)'
        done()
      client.list.create make.list
        id: 'inbox'
        name: 'Inbox'

    it 'should create user data', (done) ->
      socket.on 'message', (message) ->
        message.should.equal 'Jandal.fn_2(null,"s0")'
        done()
      client.task.create make.task
        id: 'c2'
        name: 'something'
        listId: 'inbox'

    it 'should fetch user data', (done) ->
      socket.on 'message', (message) ->
        message.should.equal 'Jandal.fn_2(null,[{' +
            '"name":"something","listId":"inbox",' +
            '"date":0,"completed":0,"notes":"","priority":0,' +
            '"id":"s0"' +
          '}])'
        done()

      client.task.fetch()

    it 'should destroy user data', (done) ->
      socket.on 'message', (message) ->
        switch message[10]
          when '2'
            message.should.equal 'Jandal.fn_2(null)'
            client.task.fetch()
          when '3'
            message.should.equal 'Jandal.fn_3(null,[])'
            done()

      client.task.destroy id: 's0'



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


      testBroadcast = (done, fn) ->

        client.socket = null
        client.callback = false

        message = fn()


        client.socket = socket
        client.callback = true

        other.on 'message', (text) ->
          text.should.equal message
          done()


      it 'should create a task', (done) ->

        model = make.task
          id: 'c1'
          listId: 'inbox'
          name: 'A brand new task'

        testBroadcast done, ->
          delete model.id
          model.id = 's1'
          client.task.create model

        client.task.create model

      it 'should create a list', (done) ->

        model = make.list
          id: 'c1'
          name: 'A brand new list'

        testBroadcast done, ->
          delete model.id
          model.id = 's0'
          client.list.create model

        client.list.create model

      it 'should update a task', (done) ->

        testBroadcast done, ->
          client.task.update
            name: 'An updated task'
            id: 's1'

        client.task.update
          id: 's1'
          name: 'An updated task'

      it 'should update a list', (done) ->

        testBroadcast done, ->
          client.list.update
            name: 'An updated list'
            id: 's0'

        client.list.update
          id: 's0'
          name: 'An updated list'

      it 'should update a pref', (done) ->

        testBroadcast done, ->
          client.pref.update
            sort: true

        client.pref.update
          sort: true

      it 'should update a pref', (done) ->

        testBroadcast done, ->
          client.pref.update
            sort: true

        client.pref.update
          sort: true

      it 'should update a pref again', (done) ->

        testBroadcast done, ->
          client.pref.update
            language: 'en-us'

        client.pref.update
          language: 'en-us'

      it 'should destroy a task', (done) ->

        testBroadcast done, ->
          client.task.destroy
            id: 's1'

        client.task.destroy
          id: 's1'

      it 'should destroy a list', (done) ->

        testBroadcast done, ->
          client.list.destroy
            id: 's0'

        client.list.destroy
          id: 's0'

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