Log    = require '../utils/log'
page   = require '../utils/page'
config = require '../config'
Auth   = require '../controllers/auth'

log = Log 'Route -> Registration', 'green'

# -----------------------------------------------------------------------------
# Registration
# -----------------------------------------------------------------------------

register = (req, res) ->

  user =
    name: req.body.name or ''
    email: req.body.email?.toLowerCase() or ''
    password: req.body.password or ''

  log 'registering user', user.name

  Auth.register(user.name, user.email, user.password)
    .then (token) ->
      link = "#{ config.url }/register/#{ token }"
      res.send link
      log link
    .fail (err) ->
      log err
      res.status 400
      res.send err

verifyRegistration = (req, res) ->
  token = req.params.token

  log 'verifying user with token', token

  Auth.verifyRegistration(token)
    .then (user) ->
      log 'verified user', user.email

      if global.DebugMode
        res.send 'success'
      else
        res.sendfile page 'auth_success'

    .fail (err) ->
      log err
      if global.DebugMode
        res.send 'error'
      else
        res.sendfile page 'error'


module.exports = [

  type: 'post'
  url: '/register'
  handler: register

,

  type: 'get'
  url: '/register/:token'
  handler: verifyRegistration

]
