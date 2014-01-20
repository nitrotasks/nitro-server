User    = require '../app/models/user'
Storage = require '../app/controllers/storage'
Time    = require '../app/utils/time'
should  = require 'should'

global.DEBUG = true

TASK = 'task'
TIME = 'time'

describe 'User class', ->

  before ->
    Storage._writeUser = Storage.writeUser
    Storage.writeUser = ->

  after ->
    Storage.writeUser = Storage._writeUser
    delete Storage._writeUser

  time = null
  user = null
  now = null

  attrs =
    data_task:
      's-0':
        name: 'buy food'
      's-1':
        name: 'eat food'
      's-2':
        name: 'release nitro'
        date: 123
        priority: 3
        notes: 'some notes'
    data_time:
      task:
        's-2':
          name: 123

  beforeEach ->
    user = new User(attrs)
    time = new Time(user)
    now = Date.now()

  it 'should set timestamps', ->
    time.set TASK, 's-0', 'name', now
    time.get(TASK, 's-0', 'name').should.equal now

  it 'should set all timestamps', ->
    time.set TASK, 's-1', '*', now
    time.get(TASK, 's-1', 'name').should.equal now

  it 'should set many timestamps', ->
    times =
      name: now
      date: now + 10
      priority: now - 10
      notes: now + 20

    time.set TASK, 's-2', times
    time.get(TASK, 's-2', 'notes').should.equal times.notes
    time.get(TASK, 's-2', 'date').should.equal times.date

  it 'should return undefined on missing items', ->
    no_key = time.get TASK, 's-0', 'missing'
    no_id  = time.get TASK, 's-100', 'name'
    no_class = time.get 'missing', 's-100', 'name'
    should.equal no_key, undefined
    should.equal no_id, undefined
    should.equal no_class, undefined

  it 'should clear timestamps', ->
    time.clear TASK, 's-2'
    model = user.data(TIME)[TASK]['s-2']
    should.equal model, undefined


