core  = require('../../core/api')
token = require('../controllers/token')
log   = require('log_')('Route -> Registration', 'green')

register = (req, res) ->

  user =
    name: req.body.name or ''
    email: req.body.email or ''
    password: req.body.password or ''

  core.auth.register(user).then (id) ->

    res.send
      id: id
      sessionToken: token.createSessionToken(id)

  .catch (err) ->
    log.warn(err)
    res.status(400)
    res.send(err)


module.exports = [

  type: 'post'
  url: '/auth/register'
  handler: register

]
