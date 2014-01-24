Q      = require 'kew'
url    = require 'url'
config = require '../config'

connect =

  ready: Q.defer()

  ###
   * - type (string) : 'production', 'development', 'testing'
  ###

  init: () ->

    # Connect to SQL database
    @engine = config.database.engine

    switch @engine

      when 'mysql'
        mysql = require 'mysql'
        @db = mysql.createConnection config.database

      when 'mssql'
        mssql = require 'mssql'
        @db = conect: (fn) ->
          new mssql.Connection config.database, fn

    @ready.resolve()

module.exports = connect
