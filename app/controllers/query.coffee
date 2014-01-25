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
  listTasks: require '../database/list_tasks'

initiateTables = (queryFn) ->
  promises = []
  for name, Table of tables
    table = new Table(queryFn)
    promises.push table.setup()
    module.exports[name] = table
  return Q.all promises


connected = connect.ready.then ->

  module.exports.query = connect.db
  # deferred = Q.defer()

  return initiateTables(connect.db)

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
