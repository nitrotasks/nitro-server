Log    = require '../utils/log'
page   = require '../utils/page'
Auth   = require '../controllers/auth'
mail   = require '../controllers/mail'

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
      res.send token

    .catch (err) ->
      log err
      res.status 400
      if typeof err is 'string'
        res.send err
      else
        res.send 'err_server'


module.exports = [

  type: 'post'
  url: '/register'
  handler: register

]
