jwt = require('jsonwebtoken')

# -----------------------------------------------------------------------------
# Login
# -----------------------------------------------------------------------------

api = (req, res) ->

  console.log req.user

  # user: <id>
  # exp: <expiry timestamp>
  # iat: <issued at timestamp>

  res.send(req.user)

module.exports = [

  type: 'post'
  url: '/api/test'
  handler: api

]
