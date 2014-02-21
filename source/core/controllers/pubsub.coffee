Promise = require('bluebird')
redis   = require('redis')
url     = require('url')
log     = require('log_')('redis', 'green')

initiated = false
cSub = null
cPub = null

###
 * Create Client
 *
 * Creates a new redis client
 *
 * - config (object) : redis config
###

createClient = (config) ->

  deferred = Promise.defer()

  if typeof config.redis_config is 'string'
    {port, hostname, auth} = url.parse(config.redis_config)
  else
    port = config.redis_config.port
    hostname = config.redis_config.host

  client = redis.createClient(port, hostname, max_attempts: 3)

  client.on 'error', (err) ->
    log.warn(err)
    deferred.reject(null)

  client.on 'ready', ->
    deferred.resolve(client)

  if auth then client.auth(auth.split(':')[1])

  return deferred.promise


###
 * Init Redis
 *
 * Creates two clients.
 * One for publishing messages, one for subscribing to them.
 *
 * - config (object) : redis config
###

init = (config) ->

  return if initiated
  initiated = true

  Promise.all [
    createClient(config)
    createClient(config)
  ]
  .spread (_pub, _sub) ->
    cPub = _pub
    cSub = _sub

publish = (channel, message) ->
  cPub.publish(channel, message)

subscribe = (channel) ->
  cSub.subscribe(channel)
  return cSub

module.exports =
  init: init
  publish: publish
  subscribe: subscribe
