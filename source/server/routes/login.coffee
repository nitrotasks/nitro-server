core  = require('../../core/api')
token = require('../controllers/token')
log   = require('log_')('Route -> Login', 'green')

login = (req, res) ->

  user =
    email: req.body.email or ''
    password: req.body.password or ''

  core.auth.login(user.email, user.password).then (id) ->

    res.send
      id: id
      sessionToken: token.createSessionToken(id)

  .catch (err) ->
    log.warn(err)
    res.status(401)
    res.send(err.message)

module.exports = [

  type: 'post'
  url: '/auth/login'
  handler: login

]
