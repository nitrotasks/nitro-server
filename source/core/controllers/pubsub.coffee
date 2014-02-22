Promise = require('bluebird')
redis   = require('redis')
url     = require('url')
log     = require('log_')('redis', 'green')

initiated = false
cSub = null
cPub = null


###
 * Parse Config
 *
 * Parses the redis config.
 * Handles both URL strings and objects
 *
 * - config (object) : redis configuration
###

parseConfig = (config) ->

  if typeof config.redis_config is 'string'
    {port, hostname, auth} = url.parse(config.redis_config)
    auth = auth.split(':')[1]
  else
    port = config.redis_config.port
    hostname = config.redis_config.host

  return {port, hostname, auth}


###
 * Create Client
 *
 * Creates a new redis client
 *
 * - config (object) : output from parseConfig
###

createClient = (config) ->

  deferred = Promise.defer()

  client = redis.createClient(config.port, config.hostname, max_attempts: 3)
  if config.auth then client.auth(config.auth)

  client.on 'error', (err) ->
    log.warn(err)
    deferred.reject(null)

  client.on 'ready', ->
    deferred.resolve(client)

  return deferred.promise


###
 * Init Redis
 *
 * Creates two clients.
 * One for publishing messages, one for subscribing to them.
 * This is because when you subscribe to a channel using redis, you can
 * no longer use that client to do anything else.
 *
 * - config (object) : redis config
###

init = (config) ->

  return if initiated
  initiated = true

  config = parseConfig(config)

  Promise.all [
    createClient(config)
    createClient(config)
  ]
  .spread (_pub, _sub) ->
    cPub = _pub
    cSub = _sub


###
 * Publish
 *
 * Publish a message to a channel using the publish client
 *
 * - channel (string) : channel to publish to
 * - message (string) : message to publish
###

publish = (channel, message) ->
  cPub.publish(channel, message)


###
 * Subscribe
 *
 * Subscribe to a channel
 *
 * - channel (string) : channel to subscribe to
 * > subscription client
###

subscribe = (channel) ->
  cSub.subscribe(channel)
  return cSub


module.exports =
  init: init
  publish: publish
  subscribe: subscribe
