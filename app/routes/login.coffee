Auth = require '../controllers/auth'

# -----------------------------------------------------------------------------
# Login
# -----------------------------------------------------------------------------

login = (req, res) ->

  user =
    email: req.body.email.toLowerCase()
    password: req.body.password

  Auth.login(user.email, user.password)
    .then (data) ->
      res.send data
    .fail (err) ->
      res.status 401
      res.send err

module.exports = [

  type: 'post'
  url: '/login'
  handler: login

]
