config   = require('../config')
core     = require('../core/index')
database = require('../core/controllers/database')

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

  database.user.create
    name: 'user_name'
    email: 'user_email_' + Date.now()
    password: 'user_password'
    pro: 0
  .then (id) ->
    setup.userId = id

setup.createList = ->

  database.list.create
    userId: setup.userId
    name: 'list_name'
  .then (id) ->
    setup.listId = id

setup.createTask = ->

  database.task.create
    userId: setup.userId
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
