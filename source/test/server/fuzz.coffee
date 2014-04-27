# FUZZ

# This is not a normal test, so don't include it with the rest of the tests

global.DEBUG = true

should      = require('should')
Promise     = require('bluebird')
log         = require('log_')('Fuzz', 'magenta')
Sandal      = require('jandal-log')
setup       = require('../setup')
GuestSocket = require('../../server/sockets/guest')
token       = require('../../server/controllers/token')

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

    switch event
      when 'create'
        obj = random.fullModel(model)
        delete obj.id
      when 'update'
        obj = random.model(model)
        delete obj.id
        delete obj.listId
      when 'destroy'
        obj = id: random.id()

    if event is 'update'
      [random.id(), obj]
    else
      [obj]


  list: (event) ->
    model = models.list

    switch event
      when 'create'
        obj = name: random.string()
      when 'update'
        obj = name: random.string()
      when 'destroy'
        obj = id: random.id()

    if event is 'update'
      [random.id(), obj]
    else
      [obj]

  pref: ->
    [random.model(models.pref)]

  command: ->
    classname = random.classname()
    event = random.event(classname)
    args = random[classname](event)
    args.unshift(classname + '.' + event)
    return args


# -----------------------------------------------------------------------------
# SETUP
# -----------------------------------------------------------------------------

describe 'Fuzz - SLOW', ->

  client = null
  socket = null

  before (done) ->
    setup()
    .then(setup.createUser)
    .then -> done()
    .done()

  beforeEach (done) ->

    socketToken = token.createSocketToken(setup.userId)

    client = new Sandal()
    socket = new GuestSocket(client.serverSocket)

    client.emit 'user.auth', socketToken, (err, user) ->
      should.equal(null, err)
      user.email.should.equal(setup._user.email)
      done()

  exec = (args) ->
    if args[0].match(/create/)
      args.push (err, id) ->
        console.log arguments
        console.log("I HAVE AN ID", id)
        ids.push(id)
    client.emit.apply(client, args)

  it 'should fuzz', (done) ->

    count = 1000

    @timeout(count * 4)

    Promise.reduce new Array(count), ->
      args = random.command()
      return exec(args)
    .then -> done()
    .done()



