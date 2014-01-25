Q      = require 'kew'
url    = require 'url'
Knex   = require 'knex'
config = require '../config'

connect =

  ready: Q.defer()

  ###
   * - type (string) : 'production', 'development', 'testing'
  ###

  init: () ->

    console.log 'intializing'

    @db = Knex.initialize
      client: config.database.engine
      connection: config.database

    # # Connect to SQL database
    # @engine = config.database.engine
    #
    # switch @engine
    #
    #   when 'mysql'
    #     mysql = require 'mysql'
    #     @db = mysql.createConnection config.database
    #
    #   when 'mssql'
    #     mssql = require 'mssql'
    #     @db = connect: (fn) ->
    #       new mssql.Connection config.database, fn

    @ready.resolve()

module.exports = connect
