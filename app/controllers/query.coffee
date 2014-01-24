Q        = require 'kew'
mssql    = require 'mssql'
connect  = require '../controllers/connect'
Log      = require '../utils/log'

log = Log 'Database', 'blue'
warn = Log 'Database', 'red'

# tables
tables =
  user: require '../database/user'
  list: require '../database/list'
  task: require '../database/task'

connected = connect.ready.then ->

  log "Connecting to #{connect.engine}"

  if connect.engine is "mysql"

    db = connect.db
    query = Q.bindPromise db.query, db

    # Export query
    module.exports.query = query

    deferred = Q.defer()

    db.connect  (err) ->
      if err
        warn 'Could not connect to database!'
        return deferred.reject err

      log 'Connected to MySQL server'

      for name, Table of tables
        table = new Table(query)
        table.setup()
        module.exports[name] = table

      deferred.resolve()

  else if connect.engine is "mssql"

    db = new mssql.Connection connect.db, (err) ->
      if err
        warn 'Could not connect to database!'
        return deferred.reject err

      log 'Connected to Microsoft SQL Server'

      query = Q.bindPromise db.request().query, db

      # Export query
      module.exports.query = query

      deferred = Q.defer()

      for name, Table of tables
        table = new Table(query)
        table.setup()
        module.exports[name] = table

      deferred.resolve()

  return deferred.promise

module.exports =
  connected: connected