Promise  = require('bluebird')
Knex     = require('knex')
sequence = require('../utils/sequence')

###
 * Tables
 *
 * These are all the database tables that will be loaded.
 * You will find them in the source/core/tables/ folder.
###

tables = [
  'user', 'list', 'task', 'pref', 'list_tasks',
  'time_task', 'time_list', 'time_pref'
].map (table) -> require('../tables/' + table)

# Defer connectiond
connected = Promise.defer()

# Database connection
knex = null


###
 * Init
 *
 * This will connect to the database using Knex.
 * Once connected, it will then check that all the tables exist.
 *
 * - config (object) : database configuration
###

init = (config) ->

  if connected.promise.isFulfilled()
    return connected.promise

  knex = exports.knex = Knex.initialize
    client: config.database_engine
    connection: config.database_config

  createTables().then -> connected.resolve()


###
 * Create Tables
 *
 * This will loop through each table, and check that it exists.
 * If it doesn't exist, it will create the table.
 * It loops sequentially and in order, so that tables that depend on other
 * tables do not cause problems.
###

createTables = ->

  if knex is null
    throw new Error 'createTables requires a database connection'

  sequence tables, (Table) ->
    name = Table::table
    table = module.exports[name] = new Table(knex)
    table.setup()


###
 * Reset Tables
 *
 * This is used for testing.
 * It will loop through each table and destroy it.
 * Afterwards, it will then wun createTables.
 * It loops sequentially and in reverse order, so that tables with
 * dependencies do not cause problems.
###

resetTables = ->

  if knex is null
    throw new Error 'ResetTables requires a database connection'

  sequence tables.slice().reverse(), (Table) ->
    name = Table::table
    table = module.exports[name]
    table._dropTable()
  .then(createTables)


module.exports =
  init: init
  connected: connected.promise
  resetTables: resetTables
