# FUZZ

# This is not a normal test, so don't include it with the rest of the tests

global.DEBUG = true

Q       = require 'kew'
Jandal  = require 'jandal'
Socket  = require '../app/controllers/socket'
Auth    = require '../app/controllers/auth'
Storage = require '../app/controllers/storage'
should  = require 'should'
setup   = require './setup'
mockjs  = require './mockjs'
client  = require './mock_client'

# -----------------------------------------------------------------------------
# Fuzzer
# -----------------------------------------------------------------------------

ids = [0, 1, 2]

events = ['create', 'update', 'destroy']

classnames = ['task', 'list', 'pref']

models =

  task:
    id: 'id'
    listId: 'id'
    date: 'date'
    name: 'string'
    notes: 'notes'
    priority: 'priority'
    completed: 'completed'

  list:
    id: 'id'
    name: 'string'
    tasks: 'ids'

  pref:
    sort: 'number'
    night: 'number'
    language: 'string'
    weekStart: 'number'
    dateFormat: 'string'
    confirmDelete: 'number'
    moveCompleted: 'number'

random =

  int: (a, b) ->
    Math.round((Math.random() * b - a) + a)

  item: (array) ->
    index = random.int(0, array.length - 1)
    array[index]

  id: ->
    random.item(ids)

  ids: ->
    arr = []
    len = random.int(0, 10)
    for i in [0..len]
      arr.push random.id()
    return arr

  string: ->
    str = ''
    len = random.int(0, 20)
    for i in [0..len]
      str += random.item 'abcdefghijklmnopqrstuvwxyz'
    return str

  number: ->
    random.int(0, 100)

  boolean: ->
    random.int(0, 1) is 0

  timestamp: ->
    random.int(0, 100000)

  priority: ->
    random.int(0, 3)

  completed: ->
    if random.boolean() then 0 else random.timestamp()

  date: ->
    if random.boolean() then 0 else random.timestamp()

  notes: ->
    if random.boolean() then '' else random.string()

  event: (classname) ->
    if classname is 'pref' then return events[1]
    index = random.int 0, events.length - 1
    events[index]

  classname: ->
    index = random.int 0, classnames.length - 1
    classnames[index]


  _callback: 0

  callback: ->
    ".fn(#{ @_callback++ })"

  model: (model) ->
    obj = {}
    for key, value of model when random.boolean()
      obj[key] = random[value]()
    return obj

  fullModel: (model) ->
    obj = {}
    for key, value of model
      obj[key] = random[value]()
    return obj

  task: (event) ->
    model = models.task
    obj = if event is 'create' then random.fullModel(model) else random.model(model)
    obj.id ?= random.id()
    return obj

  list: (event) ->
    model = models.list
    obj = if event is 'create' then random.fullModel(model) else random.model(model)
    obj.id ?= random.id()
    return obj

  pref: ->
    random.model(models.pref)

  command: ->
    classname = random.classname()
    event = random.event(classname)
    callback = random.callback()
    data = random[classname](event)
    json = JSON.stringify data

    "#{ classname }.#{ event }(#{ json })#{ callback }"


# -----------------------------------------------------------------------------
# SETUP
# -----------------------------------------------------------------------------

describe 'SLOW Fuzz', ->
  socket = null

  user =
    id: null
    token: null
    name: 'Fred'
    email: 'fred@gmail.com'
    pass: 'xkcd'

  before (done) ->
    Socket.init(null, mockjs)
    socket = mockjs.createSocket()
    client.socket = null
    setup(done)

  exec = (command) ->
    deferred = Q.defer()
    console.log '\n' + command

    socket.once 'message', (response) ->
      res = Jandal::parse(response)

      id = res.arg2

      if typeof id is 'number'
        ids.push(id)

      deferred.resolve response

    socket.reply(command)
    return deferred.promise

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

  it 'should login the user', (done) ->
    auth = client.user.auth(user.id, user.token)
    exec(auth).then (message) ->
      message.should.equal 'Jandal.fn_0(null,true)'
      done()

  it 'should fuzz', (done) ->

    promise = Q.resolve()

    for i in [0..1000]
      promise = promise.then ->
        exec random.command()

    promise.then ->
      done()

    promise.fail (err) ->
      console.log err

