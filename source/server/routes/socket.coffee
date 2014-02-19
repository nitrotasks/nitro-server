core = require('../../core/api')
log = require('log_')('Route -> Socket', 'green')
token = require('../controllers/token')

socket = (req, res) ->

  core.getUser(req.user.id)
  .then (user) ->

    res.send token.createSocketToken(user.id)

  .catch (err) ->
    log.warn err
    res.status(401)
    res.send(err)

module.exports = [

  type: 'get'
  url: '/api/socket'
  handler: socket

]
