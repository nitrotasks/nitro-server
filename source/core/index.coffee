database = require './controllers/database'

startCore = (config) ->

  database.init(config)

module.exports = startCore
