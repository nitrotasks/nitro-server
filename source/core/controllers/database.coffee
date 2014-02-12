Promise  = require('bluebird')
Knex     = require('knex')
connect  = require('../controllers/connect')
sequence = require('../utils/sequence')


# -----------------------------------------------------------------------------
# VARIABLES
# -----------------------------------------------------------------------------

# Tables
tables = [
  'user', 'list', 'task', 'pref',
  'login', 'reset', 'list_tasks',
  'time_task', 'time_list', 'time_pref',
]

# Load tables
tables.map (table) ->
  require '../database/' + table

# Ready promise
ready = Promise.defer()

# Database connection
knex = null


# -----------------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------------

init = (config) ->

  return if ready.isFulfilled()

  knex = exports.knex = Knex.initialize
    client: config.database_engine
    connection: config.database_config

  createTables().then -> ready.resolve()


# -----------------------------------------------------------------------------
# CREATE TABLES
# -----------------------------------------------------------------------------

# Sequentially create each table
createTables = ->

  if knex is null
    throw new Error 'createTables requires a database connection'


  sequence tables, (Table) ->

    name = Table::table
    table = module.exports[name] = new Table(knex)
    table.setup()


# -----------------------------------------------------------------------------
# DESTROY AND CREATE TABLES
# -----------------------------------------------------------------------------

# Sequentially drop each table in reverse order
resetTables = ->

  if knex is null
    throw new Error 'reseTables requires a database connection'

  sequence tables.slice().reverse(), (Table) ->

    name = Table::table
    table = module.exports[name]
    table._dropTable()

  .then createTables


# -----------------------------------------------------------------------------
# EXPORTS
# -----------------------------------------------------------------------------

module.exports =
  ready: ready.promise
  init: init
  connected: connected
  resetTables: resetTables
