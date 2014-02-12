Auth = require '../controllers/auth'
Log = require '../utils/log'

log = Log 'Route -> Login', 'green'

# -----------------------------------------------------------------------------
# Login
# -----------------------------------------------------------------------------

login = (req, res) ->

  user =
    email: req.body.email.toLowerCase()
    password: req.body.password

  Auth.login(user.email, user.password)
    .then (data) ->
      log 'logging in', data[2]
      res.send data
    .catch (err) ->
      res.status 401
      res.send err
    .done()

module.exports = [

  type: 'post'
  url: '/login'
  handler: login

]
