Promise = require 'bluebird'
Knex    = require 'knex'
config  = require '../config'

require 'knex-mssql'

ready = Promise.defer()

connect =

  ready: ready.promise

  ###
   * - type (string) : 'production', 'development', 'testing'
  ###

  init: () ->

    @db = Knex.initialize
      client: config.database_engine
      connection: config.database_config

    ready.resolve()

module.exports = connect
