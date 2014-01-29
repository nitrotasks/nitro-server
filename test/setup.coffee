Q        = require 'kew'
config   = require '../app/config'

# -----------------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------------

if process.env.TRAVIS
  config.use 'travis'
else
  config.use 'testing'

global.DEBUG = true

# Load controllers
database = require '../app/controllers/query'
connect  = require '../app/controllers/connect'

# Connect to databases
connect.init()

module.exports = (done) ->

  database.connected
    .then ->
      database.resetTables()
    .then ->
      done()
    .fail (err) ->
      console.log 'Error: Setup', err
