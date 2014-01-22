# FUZZ

# This is not a normal test, so don't include it with the rest of the tests

global.DEBUG = true

Q       = require 'kew'
Socket  = require '../app/controllers/socket'
Auth    = require '../app/controllers/auth'
should  = require 'should'
setup   = require './setup'
mockjs  = require './mockjs'
client  = require './mock_client'

# -----------------------------------------------------------------------------
# Fuzzer
# -----------------------------------------------------------------------------

events = ['create', 'update', 'destroy']

classnames = ['task', 'list', 'pref']

models =

  task:
    id: 'id'
    listId: 'id'
    date: 'number'
    name: 'string'
    notes: 'string'
    priority: 'number'
    completed: 'number'

  list:
    id: 'id'
    name: 'string'
    tasks: 'ids'

  pref:
    id: 'id'
    sort: 'boolean'
    night: 'string'
    language: 'string'
    weekStart: 'number'
    dateFormat: 'string'
    confirmDelete: 'boolean'
    completedDuration: 'string'

random =

  int: (a, b) ->
    Math.round((Math.random() * b - a) + a)

  char: (string) ->
    index = random.int(0, string.length - 1)
    string[index ... index + 1]

  id: ->
    random.char('csx') + random.int(0,10)

  ids: ->
    arr = []
    len = random.int(0, 20)
    for i in [0..len]
      arr.push random.id()
    return arr

  string: ->
    str = ''
    len = random.int(0, 20)
    for i in [0..len]
      str += random.char 'abcdefghijklmnopqrstuvwxyz'
    return str

  number: ->
    random.int(0, 100)

  boolean: ->
    random.int(0, 1) is 0

  event: ->
    index = random.int 0, events.length - 1
    events[index]

  classname: ->
    index = random.int 0, classnames.length - 1
    classnames[index]

  callback: ->
    if random.boolean() then return ''
    ".fn(#{ random.int(0, 100) })"

  model: (model) ->
    obj = {}
    for key, value of model when key isnt 'id' and random.boolean()
      obj[key] = random[value]()
    return obj

  task: ->
    obj = random.model(models.task)
    obj.id = random.id()
    obj.listId = random.id()
    return obj

  list: ->
    obj = random.model(models.list)
    obj.id = random.id()
    return obj

  pref: ->
    random.model(models.pref)

  command: ->
    event = random.event()
    classname = random.classname()
    callback = random.callback()
    data = random[classname]()
    json = JSON.stringify data

    "#{ classname }.#{ event }(#{ json })#{ callback }"


# -----------------------------------------------------------------------------
# SETUP
# -----------------------------------------------------------------------------

describe 'IGNORE Fuzz', ->
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
    console.log '\n', command

    timeout = setTimeout ->
      socket.off('message', callback)
      deferred.resolve()
    , 150

    callback = (response) ->
      clearTimeout timeout
      deferred.resolve(response)

    socket.once('message', callback)

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

    @timeout 60000

    promise = Q.resolve()

    for i in [0..200]
      promise = promise.then ->
        exec random.command()

    promise.then ->
      done()

    promise.fail (err) ->
      console.log err

