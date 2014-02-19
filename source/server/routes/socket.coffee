core  = require('../../core/api')
token = require('../controllers/token')
log   = require('log_')('Route -> Socket', 'green')

socket = (req, res) ->

  userId = req.user.id

  # Check that user exists
  core.getUser(userId).then ->

    res.send
      socketToken: token.createSocketToken(userId)

  .catch (err) ->
    log.warn err
    res.status(401)
    res.send(err)

module.exports = [

  type: 'get'
  url: '/api/socket'
  handler: socket

]
