###
 * Wrap redis commands in promises
 * 
 * Instead of binding every method, we only bind the ones that we use.
###

Q = require 'kew'
connect = require '../controllers/connect'

redis = null
wrapper = {}
methods = [
  'expire', 'setex',
  'del', 'exists', 'keys',
  'hmset', 'hgetall', 'hset', 'hget', 'hdel', 'hexists'
]

# Bind methods
connect.ready.then ->
  redis = connect.redis
  for method in methods
    wrapper[method] = Q.bindPromise redis[method], redis

module.exports = wrapper
