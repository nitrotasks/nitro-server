Q         = require 'kew'
nodeRedis = require 'redis'
mysql     = require 'mysql'
config    = require '../config'

connect =

  ready: Q.defer()

  ###
   * - type (string) : 'production', 'development', 'testing'
  ###

  init: (type) ->

    # Load configuration
    cf = config[type]

    # Connect to MySQL
    @mysql = mysql.createConnection cf.mysql

    # Connect to Redis
    @redis = nodeRedis.createClient cf.redis.port, cf.redis.host

    @ready.resolve()

module.exports = connect
