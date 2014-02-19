core  = require('../../core/api')
token = require('../controllers/token')
log   = require('log_')('Route -> Refresh', 'green')

refresh = (req, res) ->

  core.getUser(req.user.id).then (user) ->

    res.send
      sessionToken: token.createSessionToken(user.id)

  .catch (err) ->
    log.warn err
    res.status(401)
    res.send(err)

module.exports = [

  type: 'get'
  url: '/api/refresh_token'
  handler: refresh

]
