Log  = require('log_')('Route -> Registration', 'green')
core = require('../../core/api')

# -----------------------------------------------------------------------------
# Registration
# -----------------------------------------------------------------------------

register = (req, res) ->

  user =
    name: req.body.name or ''
    email: req.body.email?.toLowerCase() or ''
    password: req.body.password or ''

  log 'registering user', user.name

  core.auth.register(user)
  .then (id) ->
    req.session.passport = user: id
    res.send(id)

  .catch (err) ->
    log.warn(err)
    res.status(400)

    message = err.message

    if not message.match(/^err_/)
      message = 'err_server'

    res.send(message)


module.exports = [

  type: 'post'
  url: '/auth/register'
  handler: register

]
