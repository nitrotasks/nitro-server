Q      = require 'kew'
url    = require 'url'
mysql  = require 'mysql'
config = require '../config'

connect =

  ready: Q.defer()

  ###
   * - type (string) : 'production', 'development', 'testing'
  ###

  init: () ->

    # Connect to MySQL
    @engine = config.database.engine
    if @engine is "mysql"
      @db = mysql.createConnection config.database
    else if @engine is "mssql"
      @db = config.database

    @ready.resolve()

module.exports = connect
