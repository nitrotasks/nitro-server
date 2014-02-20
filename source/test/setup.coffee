config   = require('../config')
core     = require('../core/index')
database = require('../core/controllers/database')
Users    = require('../core/models/user')

# -----------------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------------

global.DEBUG = true
global.DEBUG_ROUTES = true

enviroment = process.env.NODE_ENV ?= 'testing'
config.use(enviroment)

setup = ->

  core(config)
  .then(database.resetTables)
  .return(setup)

setup._email = 'user_email'

setup._user =
  name: 'user_name'
  password: 'user_password'
  pro: 0

setup._pref =
  sort: 0
  night: 0
  language: 'en-us'
  weekStart: 0
  dateFormat: 'dd/mm/yy'
  confirmDelete: 0
  moveCompleted: 0

setup._list =
  name: 'list_name'

setup._task =
  name: 'task_name'
  notes: 'task_notes'
  date: 0
  priority: 0
  completed: 0

setup._timeList =
  name: 1
  tasks: 1

setup._timeTask =
  listId: 1
  name: 1
  notes: 1
  date: 1
  priority: 1
  completed: 1

setup._timePref =
  sort: 1
  night: 1
  language: 1
  weekStart: 1
  dateFormat: 1
  confirmDelete: 1
  moveCompleted: 1

setup.createUser = (email) ->

  if typeof email isnt 'string' then email = ''
  setup._user.email = setup._email + email

  Users.create(setup._user)
  .then (user) ->
    setup.user = user
    setup.userId = user.id

setup.createPref = ->

  setup._pref.userId = setup.userId

  setup.user.pref.destroy()
  .then ->
    setup.user.pref.create(setup._pref)
  .then (id) ->
    setup.prefId = id

setup.createList = ->

  setup.user.list.create(setup._list)
  .then (id) ->
    setup._list.id = id
    setup.listId = id

setup.createTask = ->

  setup._task.listId = setup.listId

  setup.user.task.create(setup._task)
  .then (id) ->
    setup._task.id = id
    setup.taskId = id
    database.list_tasks.create(id, setup.listId)

setup.createTimeList = ->

  setup._timeList.id = setup.listId
  database.time_list.create(setup._timeList)

setup.createTimeTask = ->

  setup._timeTask.id = setup.taskId
  database.time_task.create(setup._timeTask)

setup.createTimePref = ->

  setup._timePref.id = setup.userId
  database.time_pref.create(setup._timePref)

module.exports = setup
