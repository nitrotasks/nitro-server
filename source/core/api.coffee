Users = require('./models/user')
auth = require('./controllers/auth')
analytics = require('./controllers/analytics')
Sync = require('./controllers/sync')

api =

  auth: auth

  getUser: (userId) ->
    Users.read(userId)

  analytics: analytics

  Sync: Sync

module.exports = api
