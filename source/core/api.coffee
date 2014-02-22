Users     = require('./models/user')
auth      = require('./controllers/auth')
Sync      = require('./controllers/sync')
event     = require('./controllers/event')

api =

  auth: auth

  getUser: (userId) ->
    Users.get(userId)

  Sync: Sync

  event: event

module.exports = api
