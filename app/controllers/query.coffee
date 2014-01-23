Q        = require 'kew'
connect  = require '../controllers/connect'
Log      = require '../utils/log'

log = Log 'Database', 'blue'
warn = Log 'Database', 'red'

# Modules
modules = module.exports =
  task: require '../database/task'
  user: require '../database/user'
  util: require '../database/util'

modules.connected = connect.ready.then ->

  log 'Connecting to MySQL'

  db = connect.mysql
  query = Q.bindPromise db.query, db

  deferred = Q.defer()

  db.connect  (err) ->
    if err
      warn 'Could not connect to MySQL database!'
      return deferred.reject err

    log 'Connected to MySQL server'

    for name, mod of modules when mod.setup?
      mod.setup(query)

    deferred.resolve()

  return deferred.promise
