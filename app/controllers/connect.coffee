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
    @mysql = mysql.createConnection config.mysql

    @ready.resolve()

module.exports = connect
