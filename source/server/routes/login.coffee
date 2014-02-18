core = require('../../core/api')
jwt = require('jsonwebtoken')
log = require('log_')('Route -> Login', 'green')

# -----------------------------------------------------------------------------
# Login
# -----------------------------------------------------------------------------

login = (req, res) ->

  user =
    email: req.body.email.toLowerCase()
    password: req.body.password

  console.log user

  core.auth.login(user.email, user.password)
  .then (id) ->

    token = jwt.sign({ user: id }, 'secret', expiresInMinutes: 20)
    res.send { token }

  .catch (err) ->
    log.warn err
    res.status(401)
    res.send(err)

module.exports = [

  type: 'post'
  url: '/login'
  handler: login

]
