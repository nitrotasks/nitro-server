Sync   = require '../app/controllers/sync'
Auth   = require '../app/controllers/auth'
setup  = require './setup'
should = require 'should'
Q      = require 'kew'

LIST = 'list'
TASK = 'task'
PREF = 'pref'

describe 'Sync API', ->

  user = null
  sync = null

  before (done) -> setup ->
    Auth.register('George', 'mail@example.com', 'password')
    .then (token) ->
      Auth.verifyRegistration(token)
    .then (_user) ->
      user = _user
      done()
    .fail (err) ->
      console.log err

  beforeEach ->
    sync = new Sync(user)

  it 'should add lists and tasks', ->

    # -----
    # Lists
    # -----

    sync.create LIST, {name: 'List 1', tasks: []}
    sync.create LIST, {name: 'List 2', tasks: []}
    sync.create LIST, {name: 'List 3', tasks: []}

    # Check lists exist
    lists = sync.user.data(LIST)
    lists['s0'].name.should.equal 'List 1'
    lists['s1'].name.should.equal 'List 2'
    lists['s2'].name.should.equal 'List 3'

    # -----
    # Tasks
    # -----

    sync.create TASK, {name: 'Task 1', list: 's0'}
    sync.create TASK, {name: 'Task 2', list: 's0'}
    sync.create TASK, {name: 'Task 3', list: 's0'}

    # Check tasks exist
    tasks = sync.user.data(TASK)
    tasks['s0'].name.should.equal 'Task 1'
    tasks['s1'].name.should.equal 'Task 2'
    tasks['s2'].name.should.equal 'Task 3'

    lists['s0'].tasks.should.eql ['s0', 's1', 's2']


  it 'should handle task and list updates', ->

    # -----
    # Tasks
    # -----

    sync.update TASK, {id: 's0', name: 'Task 1 has been renamed'}
    sync.update TASK, {id: 's1', name: 'Task 2 has been renamed'}
    sync.update TASK, {id: 's2', name: 'Task 3 has been renamed'}

    # Check names have been updated
    tasks = sync.user.data(TASK)
    tasks['s0'].name.should.equal 'Task 1 has been renamed'
    tasks['s1'].name.should.equal 'Task 2 has been renamed'
    tasks['s2'].name.should.equal 'Task 3 has been renamed'

    # -----
    # Lists
    # -----

    sync.update LIST, {id: 's0', name: 'List 1 has been renamed'}
    sync.update LIST, {id: 's1', name: 'List 2 has been renamed'}
    sync.update LIST, {id: 's2', name: 'List 3 has been renamed'}

    # Check names have been updated
    lists = sync.user.data(LIST)
    lists['s0'].name.should.equal 'List 1 has been renamed'
    lists['s1'].name.should.equal 'List 2 has been renamed'
    lists['s2'].name.should.equal 'List 3 has been renamed'


  it 'should handle task and list destruction', ->

    # -----
    # Tasks
    # -----

    sync.destroy TASK, 's0'
    sync.destroy TASK, 's1'
    sync.destroy TASK, 's2'

    # Check tasks have been deleted
    tasks = sync.user.data(TASK)
    tasks['s0'].should.have.keys 'deleted', 'id'
    tasks['s1'].should.have.keys 'deleted', 'id'
    tasks['s2'].should.have.keys 'deleted', 'id'

    # -----
    # Lists
    # -----

    sync.destroy LIST, 's0'
    sync.destroy LIST, 's1'
    sync.destroy LIST, 's2'

    # Check lists have been deleted
    lists = sync.user.data(TASK)
    lists['s0'].should.have.keys 'deleted', 'id'
    lists['s1'].should.have.keys 'deleted', 'id'
    lists['s2'].should.have.keys 'deleted', 'id'


  it 'should handle offline sync', ->

    now = Date.now()

    listId = sync.create LIST, {name: 'Just a list', tasks: []}

    tasks = [
      sync.create TASK, {name: 'Task 1', list: listId}
      sync.create TASK, {name: 'Task 2', list: listId}
      sync.create TASK, {name: 'Task 3', list: listId}
    ]

    queue = [
      # Destroy tasks
      [ 'destroy', TASK, tasks[0], now ]
      [ 'destroy', TASK, tasks[1], now ]
      [ 'destroy', TASK, tasks[2], now ]

      # Update the list
      [ 'update', LIST, {id: listId, name: 'Changed'}, now ]

      # Create a new list
      [ 'create',  LIST, {id: 'c1', name:LIST, tasks:[]}, now ]

      # Create a new task
      [ 'create', TASK, {id: 'c1', name:TASK, list: 'c1'}, now ]
    ]

    console.log sync.sync(queue)

###
