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

    # Create three lists
    sync.list_create {name: 'List 1'}
    sync.list_create {name: 'List 2'}
    sync.list_create {name: 'List 3'}

    # Check lists exist
    lists = sync.user.data(LIST)
    lists.should.eql
      s0: name: 'List 1', tasks: [], id: 's0'
      s1: name: 'List 2', tasks: [], id: 's1'
      s2: name: 'List 3', tasks: [], id: 's2'

    # Create three tasks
    sync.task_create {name: 'Task 1', listId: 's0'}
    sync.task_create {name: 'Task 2', listId: 's0'}
    sync.task_create {name: 'Task 3', listId: 's0'}

    # Check tasks exist
    tasks = sync.user.data(TASK)
    tasks.should.eql
      s0: name: 'Task 1', listId: 's0', id: 's0'
      s1: name: 'Task 2', listId: 's0', id: 's1'
      s2: name: 'Task 3', listId: 's0', id: 's2'

    # Should add tasks to lists
    lists.s0.tasks.should.eql ['s0', 's1', 's2']


  it 'should handle task and list updates', ->

    tasks = sync.user.data(TASK)
    lists = sync.user.data(LIST)
    pref = sync.user.data(PREF)

    # Update task names
    sync.task_update {id: 's0', name: 'Task 1 has been renamed'}
    sync.task_update {id: 's1', name: 'Task 2 has been renamed'}
    sync.task_update {id: 's2', name: 'Task 3 has been renamed'}

    # Check names have been updated
    tasks.s0.name.should.equal 'Task 1 has been renamed'
    tasks.s1.name.should.equal 'Task 2 has been renamed'
    tasks.s2.name.should.equal 'Task 3 has been renamed'

    # Update list names
    sync.list_update {id: 's0', name: 'List 1 has been renamed'}
    sync.list_update {id: 's1', name: 'List 2 has been renamed'}
    sync.list_update {id: 's2', name: 'List 3 has been renamed'}

    # Check names have been updated
    lists.s0.name.should.equal 'List 1 has been renamed'
    lists.s1.name.should.equal 'List 2 has been renamed'
    lists.s2.name.should.equal 'List 3 has been renamed'

    # Update pref
    sync.pref_update
      id: 's0',
      sort: true
      language: 'en-US'

    pref.s0.sort.should.equal true
    pref.s0.language.should.equal 'en-US'


  it 'should move a task to another list', ->

    tasks = sync.user.data(TASK)
    lists = sync.user.data(LIST)

    # Check current status
    tasks.s0.listId.should.equal 's0'
    lists.s0.tasks.should.eql ['s0', 's1', 's2']
    lists.s1.tasks.should.eql []

    # Move task
    sync.task_update {id: 's0', listId: 's1'}

    # Check task has been moved
    tasks.s0.listId.should.equal 's1'
    lists.s0.tasks.should.eql ['s1', 's2']
    lists.s1.tasks.should.eql ['s0']


  it 'should respect update timestamps', ->

    # Travel 10 seconds back in time!
    now = Date.now() - 1000 * 10

    should.equal null, sync.task_update({
      id: 's1', name: 'Task 1 in the past'
    }, {
      name: now
    })

    should.equal null, sync.list_update({
      id: 's2', name: 'List 2 in the past'
    },{
      name: now
    })

    should.equal null, sync.pref_update({
      id: 's0', sort: false
    }, {
      sort: now
    })


  it 'should not fail when trying to update a model that does not exist', ->

    # Tasks that don't exist
    should.equal null, sync.task_update {id: 's4', name: 'Task 4'}

    # Lists that don't exist
    should.equal null, sync.list_update {id: 's4', name: 'List 4'}


  it 'should handle task and list destruction', ->

    # Fetch data
    tasks = sync.user.data(TASK)
    lists = sync.user.data(LIST)

    # Check that task is in the list
    lists.s1.tasks.should.eql ['s0']

    # Destroy a task
    sync.task_destroy 's0'

    # Check that the task has been deleted
    tasks.s0.should.eql id: 's0', deleted: true
    lists.s1.tasks.should.eql []

    # Destroy some lists
    sync.list_destroy 's1'
    sync.list_destroy 's2'

    # Check that the lists have been deleted
    lists.s1.should.eql id: 's1', deleted: true
    lists.s2.should.eql id: 's2', deleted: true

    # Destroy a list that still has tasks in it
    sync.list_destroy 's0'

    # Check that everything has been deleted
    lists.s0.should.eql id: 's0', deleted: true
    tasks.s1.should.eql id: 's1', deleted: true
    tasks.s2.should.eql id: 's2', deleted: true


  it 'should not fail when destroying a model that does not exist', ->

    # Models that have never existed
    should.equal null, sync.task_destroy 's4'
    should.equal null, sync.list_destroy 's4'

    # Models that exist but are deleted
    should.equal null, sync.task_destroy 's0'
    should.equal null, sync.list_destroy 's0'

  it 'should not fail when updating a model that has been deleted', ->

    # Models that exist but are deleted
    should.equal null, sync.task_update {id: 's0', name: 'test'}
    should.equal null, sync.list_update {id: 's0', name: 'test'}
