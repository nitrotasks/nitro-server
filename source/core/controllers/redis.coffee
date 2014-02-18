Promise = require('bluebird')
redis   = require('redis')
url     = require('url')
log     = require('log_')('redis', 'blue')

ready = Promise.defer()

###
 * - type (string) : 'production', 'development', 'testing'
###

init = (config) ->

  if typeof config.redis_config is 'string'
    {port, hostname, auth} = url.parse(config.redis_config)
  else
    port = config.redis_config.port
    hostname = config.redis_config.host

  client = redis.createClient(port, hostname, max_attempts: 3)
  client.on 'error', ->
    log.warn('Could not connect to Redis')
    ready.reject new Error('Could not connect to redis')

  if auth then client.auth(auth.split(':')[1])

  ready.resolve(client)

module.exports =
  init: init
  ready: ready.promise
