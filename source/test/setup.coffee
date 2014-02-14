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

setup.createUser = ->

  Users.create
    name: 'user_name'
    email: 'user_email_' + Date.now()
    password: 'user_password'
    pro: 0
  .then (user) ->
    setup.user = user
    setup.userId = user.id

setup.createPref = ->

  setup.user.pref.create
    sort: 0
    night: 0
    language: 'en-us'
    weekStart: 0
    dateFormat: 'dd/mm/yy'
    confirmDelete: 0
    moveCompleted: 0
  .then (id) ->
    setup.prefId = id

setup.createList = ->

  setup.user.lists.create
    name: 'list_name'
  .then (id) ->
    setup.listId = id

setup.createTask = ->

  setup.user.tasks.create
    listId: setup.listId
    name: 'task_name'
    notes: 'task_notes'
    date: 0
    priority: 0
    completed: 0
  .then (id) ->
    setup.taskId = id
    database.list_tasks.create(setup.listId, id)

module.exports = setup
