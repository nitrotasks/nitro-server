core = require('../../core/api')
Log = require('log_')('Route -> Login', 'green')

# -----------------------------------------------------------------------------
# Login
# -----------------------------------------------------------------------------

login = (req, res) ->

  user =
    email: req.body.email.toLowerCase()
    password: req.body.password

  core.auth.login(user.email, user.password)
  .then (id) ->
    req.session.passport = user: id
    res.send(id)
  .catch (err) ->
    res.status(401)
    res.send(err)
  .done()

module.exports = [

  type: 'post'
  url: '/login'
  handler: login

]
