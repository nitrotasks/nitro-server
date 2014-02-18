Promise  = require('bluebird')
redis    = require('./controllers/redis')
database = require('./controllers/database')

startCore = (config) ->

  Promise.all [
    database.init(config)
    redis.init(config)
  ]

module.exports = startCore
