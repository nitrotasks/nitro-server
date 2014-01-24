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

connected = connect.ready.then ->

  log 'Connecting to MySQL'

  db = connect.mysql
  query = Q.bindPromise db.query, db

  # Export query
  module.exports.query = query

  deferred = Q.defer()

  db.connect  (err) ->
    if err
      warn 'Could not connect to MySQL database!'
      return deferred.reject err

    log 'Connected to MySQL server'

    for name, Table of tables
      table = new Table(query)
      table.setup()
      module.exports[name] = table

    deferred.resolve()

  return deferred.promise

module.exports =
  connected: connected