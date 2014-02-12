connect = require '../controllers/connect'
CHANNEL = 'analytics'

redis = null

connect.ready.then ->
  redis = connect.redis

analytics = (event, id) ->
  message = if id then "#{ id }|#{ event }" else event
  redis.publish CHANNEL, message

module.exports = analytics