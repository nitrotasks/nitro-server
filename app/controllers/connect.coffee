Q      = require 'kew'
url    = require 'url'
redis  = require 'redis'
mysql  = require 'mysql'
config = require '../config'

connect =

  ready: Q.defer()

  ###
   * - type (string) : 'production', 'development', 'testing'
  ###

  init: () ->

    # Connect to MySQL
    @mysql = mysql.createConnection config.mysql

    # Connect to Redis
    if process.env.REDISTOGO_URL
      rtg = url.parse(process.env.REDISTOGO_URL);
      console.log rtg
      @redis = redis.createClient(rtg.port, rtg.hostname)
      @redis.auth rtg.auth.split(':')[1]
    else
      @redis = redis.createClient config.redis.port, config.redis.host

    @ready.resolve()

module.exports = connect
