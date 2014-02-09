Promise  = require 'bluebird'
connect  = require '../controllers/connect'
Log      = require '../utils/log'
sequence = require '../utils/sequence'

log = Log 'Database', 'blue'
warn = Log 'Database', 'red'

# tables
tables = [
  require '../database/user'
  require '../database/list'
  require '../database/task'
  require '../database/pref'
  require '../database/login'
  require '../database/reset'
  require '../database/register'
  require '../database/list_tasks'
  require '../database/time_task'
  require '../database/time_list'
  require '../database/time_pref'
]

# Sequentially create each table
createTables = ->

  sequence tables, (Table) ->

    name = Table::table
    table = module.exports[name] = new Table(connect.db)
    table.setup()

# Sequentially drop each table in reverse order
resetTables = ->

  sequence tables.reverse(), (Table) ->

    name = Table::table
    table = module.exports[name]
    table._dropTable()

  .then ->

    # Unreverse the tables
    tables.reverse()
    createTables()

connected = connect.ready.then ->

  module.exports.query = connect.db
  return createTables(connect.db)

module.exports =
  connected: connected
  resetTables: resetTables
