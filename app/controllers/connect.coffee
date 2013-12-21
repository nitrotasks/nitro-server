Q         = require 'kew'
nodeRedis = require 'redis'
mysql     = require 'mysql'
config    = require '../config'

connect =

  ready: Q.defer()

  ###
   * - type (string) : 'production', 'development', 'testing'
  ###

  init: () ->

    # Connect to MySQL
    @mysql = mysql.createConnection config.mysql

    # Connect to Redis
    @redis = nodeRedis.createClient config.redis.port, config.redis.host

    @ready.resolve()

module.exports = connect
