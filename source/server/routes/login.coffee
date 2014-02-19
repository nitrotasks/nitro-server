core = require('../../core/api')
log = require('log_')('Route -> Login', 'green')
token = require('../controllers/token')

# -----------------------------------------------------------------------------
# Login
# -----------------------------------------------------------------------------

login = (req, res) ->

  user =
    email: req.body.email?.toLowerCase() or ''
    password: req.body.password or ''

  console.log user

  core.auth.login(user.email, user.password)
  .then (id) ->
    res.send token.createSessionToken(id)

  .catch (err) ->
    log.warn err
    res.status(401)
    res.send(err.message)

module.exports = [

  type: 'post'
  url: '/login'
  handler: login

]
