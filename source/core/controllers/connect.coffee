Promise = require 'bluebird'
Knex    = require 'knex'
redis   = require 'redis'
url     = require 'url'
config  = require '../config'
Log     = require '../utils/log'
require 'knex-mssql'

warn = Log('connect', 'red')

ready = Promise.defer()

connect =

  ready: ready.promise

  ###
   * - type (string) : 'production', 'development', 'testing'
  ###

  init: () ->

    if typeof config.redis_config is 'string'
      {port, hostname, auth} = url.parse(config.redis_config)
    else
      port = config.redis_config.port
      hostname = config.redis_config.host

    @redis = redis.createClient(port, hostname, max_attempts: 3)
    @redis.on 'error', -> warn 'Could not connect to Redis'
    if auth then @redis.auth(auth.split(':')[1])

    @db = Knex.initialize
      client: config.database_engine
      connection: config.database_config

    ready.resolve()

module.exports = connect
