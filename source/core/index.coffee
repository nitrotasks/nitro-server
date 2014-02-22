Promise  = require('bluebird')
pubsub    = require('./controllers/pubsub')
database = require('./controllers/database')

startCore = (config) ->

  Promise.all [
    database.init(config)
    pubsub.init(config)
  ]

module.exports = startCore
