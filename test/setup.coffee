Q        = require 'kew'
config   = require '../app/config'

# -----------------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------------

config.use 'testing'
global.DEBUG = true

# Load controllers
database = require '../app/controllers/database'
connect  = require '../app/controllers/connect'
Storage  = require '../app/controllers/storage'

# Connect to databases
connect.init()

module.exports = (done) ->

  Storage.releaseAll()

  promise = Q.all [
    connect.ready
    database.connected
  ]

  promise
    .then ->
      database.deleteAll 'user'
    .then ->
      done()
    .fail (err) ->
      console.log 'Error: Setup', err
