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
    email: 'user_email'
    password: 'user_password'
    pro: 0

setup.createList = ->

  database.list.create
    userId: 1
    name: 'list_name'

setup.createTask = ->

  database.task.create
    userId: 1
    listId: 1
    name: 'task_name'
    notes: 'task_notes'
    date: 0
    priority: 0
    completed: 0
  .then ->
    database.list_tasks.create(1, 1)

module.exports = setup
