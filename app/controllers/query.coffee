Q        = require 'kew'
connect  = require '../controllers/connect'
Log      = require '../utils/log'

log = Log 'Database', 'blue'
warn = Log 'Database', 'red'

# tables
tables =
  user: require '../database/user'
  list: require '../database/list'
  task: require '../database/task'
  pref: require '../database/pref'
  login: require '../database/login'
  reset: require '../database/reset'
  register: require '../database/register'
  list_tasks: require '../database/list_tasks'
  time_task: require '../database/time_task'
  time_list: require '../database/time_list'
  time_pref: require '../database/time_pref'

createTables = ->
  promise = Q.resolve()
  for name, Table of tables
    module.exports[name] = table = new Table(connect.db)
    do (table) -> promise = promise.then -> table.setup()
  return promise

resetTables = ->
  # Sequentially drop each table in reverse order
  promise = Q.resolve()
  for name in Object.keys(tables) by -1
    do (name) -> promise = promise.then -> module.exports[name]._dropTable()
  promise.then -> createTables()

connected = connect.ready.then ->

  module.exports.query = connect.db
  # deferred = Q.defer()

  return createTables(connect.db)

  # switch connect.engine

  #   when 'mysql'

  #     query = Q.bindPromise db.query, db

  #     # Export query
  #     module.exports.query = query

  #     db.connect  (err) ->
  #       if err
  #         warn 'Could not connect to database!'
  #         return deferred.reject err

  #       log 'Connected to MySQL server'

  #       initiateTables(query)

  #       deferred.resolve()


  #   when 'mssql'

  #     db.connect (err) ->

  #       if err
  #         warn 'Could not connect to database!'
  #         return deferred.reject err

  #       log 'Connected to Microsoft SQL Server'

  #       query = Q.bindPromise db.request().query, db

  #       # Export query
  #       module.exports.query = query

  #       initiateTables(query)

  #       deferred.resolve()

  # return deferred.promise

module.exports =
  connected: connected
  resetTables: resetTables
