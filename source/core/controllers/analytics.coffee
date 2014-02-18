redis = require('../controllers/redis')

CHANNEL = 'analytics'

client = null

redis.ready.then (_client) ->
  client = _client

analytics = (event, id) ->
  return unless client
  message = if id then "#{ id }|#{ event }" else event
  client.publish(CHANNEL, message)

module.exports = analytics
