jwt = require('jsonwebtoken')

# -----------------------------------------------------------------------------
# Login
# -----------------------------------------------------------------------------

api = (req, res) ->

  console.log req.user

  # -> 
  # user: <id>
  # exp: <expiry timestamp>
  # iat: <issued at timestamp>

  res.end()

module.exports = [

  type: 'post'
  url: '/api/protected'
  handler: api

]
