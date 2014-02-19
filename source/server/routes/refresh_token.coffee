core = require('../../core/api')
log = require('log_')('Route -> Refresh', 'green')
token = require('../controllers/token')

# -----------------------------------------------------------------------------
# Login
# -----------------------------------------------------------------------------

login = (req, res) ->

  core.getUser(req.user.id)
  .then (user) ->

    res.send token.createSessionToken(user.id)

  .catch (err) ->
    log.warn err
    res.status(401)
    res.send(err)

module.exports = [

  type: 'get'
  url: '/api/refresh_token'
  handler: login

]
