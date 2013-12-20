Warn = require('./utils/log')('Warning', 'red')
Log  = require('./utils/log')('Info', 'green')

# Handle debug mode
global.DebugMode = off

# Enable debug mode if passed as argument
if '--debug' in process.argv
  global.DebugMode = on
  Warn 'Running in debug mode!'

if module.parent is null

  # Port 443 should be piped to 8080
  port = 8080

  # Override port
  if '-p' in process.argv
    index = process.argv.indexOf('-p')
    port = process.argv[index + 1]

  # Connect to database
  connect = require './controllers/connect'

  if global.DebugMode
    connect.init 'development'
  else
    connect.init 'production'

  # Start api
  api = require './controllers/api'
  server = api.listen port

  Log "Starting server on port #{ port }"

  # Start sync
  Sync = require './controllers/sync'
  Sync.init server

else

  global.DebugMode = true
  module.exports = require './controllers/api'
