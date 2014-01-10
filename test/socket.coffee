Socket  = require '../app/controllers/socket'
Storage = require '../app/controllers/storage'
Auth    = require '../app/controllers/auth'
should  = require 'should'
setup   = require './setup'
mockjs  = require './mockjs'

describe '[Socket]', ->

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

  afterEach ->
    socket.end()

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


  describe '[auth]', ->

    it 'should try to auth', (done) ->
      socket.on 'close', ->
        socket.open.should.equal false
        done()
      socket.reply 'user.auth(20,"token").fn(20)'


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
        message.should.equal 'Jandal.fn_1(true)'
        socket.end()
        done()
      socket.reply "user.auth(#{ user.id },\"#{ user.token }\").fn(1)"


  describe '[methods]', ->

    beforeEach (done) ->
      socket.reply "user.auth(#{ user.id },\"#{ user.token }\").fn(1)"
      socket.on 'message', (message) ->
        if message is 'Jandal.fn_1(true)'then done()

    it 'should get user info', (done) ->
      socket.on 'message', (message) ->
        message.should.equal 'Jandal.fn_2({"name":"Fred","email":"fred@gmail.com","pro":0})'
        done()
      socket.reply 'user.info().fn(2)'

    it 'should create user data', (done) ->
      socket.on 'message', (message) ->
        message.should.equal 'Jandal.fn_2("s0")'
        done()
      socket.reply 'task.create({"name":"something","list":20}).fn(2)'

    it 'should fetch user data', (done) ->
      socket.on 'message', (message) ->
        message.should.equal 'Jandal.fn_2([{"name":"something","list":20,"id":"s0"}])'
        done()
      socket.reply 'task.fetch().fn(2)'

    it 'should broadcast events to other sockets', (done) ->
      other = mockjs.createSocket()
      other.reply "user.auth(#{ user.id },\"#{ user.token }\").fn(1)"

      other.on 'message', (message) ->
        switch message[10]
          when '1'
            message.should.equal 'Jandal.fn_1(true)'
            socket.reply 'task.update({"id":"s0","name":"Old task with new name"}).fn(2)'
          else
            message.should.equal 'task.update({"name":"Old task with new name","list":20,"id":"s0"})'
            other.end()
            done()

    it 'should destroy user data', (done) ->
      socket.on 'message', (message) ->
        switch message[10]
          when '2'
            message.should.equal 'Jandal.fn_2()'
            socket.reply 'task.fetch().fn(3)'
          when '3'
            message.should.equal 'Jandal.fn_3([])'
            done()
      socket.reply 'task.destroy("s0").fn(2)'


    describe '[queue]', ->

      CREATE = 0
      UPDATE = 1
      DESTROY = 2

      beforeEach (done) ->
        Storage.get(user.id).then (user) ->
          user.wipe()
          done()

      test = (input, output, done) ->
        socket.on 'message', (message) ->
          [list, task, pref] = JSON.parse('[' + message[12..-2] + ']')
          list.should.eql output.list
          task.should.eql output.task
          done()
        socket.reply "model.sync(#{ JSON.stringify input }).fn(2)"


      it 'create lists and tasks simultaneously', (done) ->

        input =
          list:
            c20: [CREATE, {name: 'list 1', tasks: ['c12', 'c13']}]
            c33: [CREATE, {name: 'list 2', tasks: ['c14', 'c15']}]
          task:
            c12: [CREATE, {name: 'task 1', listId: 'c20'}]
            c13: [CREATE, {name: 'task 2', listId: 'c20'}]
            c14: [CREATE, {name: 'task 3', listId: 'c33'}]
            c15: [CREATE, {name: 'task 4', listId: 'c33'}]

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

        socket.reply 'list.create({"id":"c0","name":"List 1","tasks":[]})'
        socket.reply 'task.create({"id":"c1","name":"Task 1","listId":"s0"})'
        socket.reply 'task.create({"id":"c2","name":"Task 2","listId":"s0"})'
        socket.reply 'task.create({"id":"c3","name":"Task 3","listId":"s0"})'

        input =

          task:
            s0: [UPDATE, {name: 'Task 1 - Updated', listId: 'c1'}]
            s1: [UPDATE, {name: 'Task 2 - Updated'}]
            s2: [UPDATE, {name: 'Task 3 - Updated', listId: 'c1'}]

          list:
            s0: [UPDATE, {name: 'List 1 - Updated'}]
            c1: [CREATE, {name: 'List 2'}]


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

        socket.reply 'list.create({"id":"c0","name":"List 1","tasks":[]})'
        socket.reply 'task.create({"id":"c1","name":"Task 1","listId":"s0"})'
        socket.reply 'task.create({"id":"c2","name":"Task 2","listId":"s0"})'
        socket.reply 'task.create({"id":"c3","name":"Task 3","listId":"s0"})'

        input =

          task:
            s0: [DESTROY, 's0']
            s1: [DESTROY, 's1']
            s2: [DESTROY, 's2']
            c1: [CREATE, {name: 'Task 4', listId: 'c1'}]

          list:
            s0: [UPDATE, {name: 'List 1 - Updated'}]
            c1: [CREATE, {name: 'List 2', tasks: []}]

        output =

          list: [
            id: 's0'
            name: 'List 1 - Updated'
            tasks: []
          ,
            id: 's1'
            name: 'List 2'
            tasks: [ 's3' ]
          ]

          task: [
            id: "s3"
            name: "Task 4"
            listId: "s1"
          ]

        test input, output, done
