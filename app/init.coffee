
Warn = require('./log')('Warning', 'red')
Log  = require('./log')('Info', 'green')

# Handle debug mode
global.DebugMode = off

# Enable debug mode if passed as argument
if '--debug' in process.argv
  global.DebugMode = on
  Warn 'Running in debug mode!'

# Port 443 should be piped to 8080
port = 8080

# Override port
if '-p' in process.argv
  index = process.argv.indexOf('-p')
  port = process.argv[index + 1]

# Start api
api = require './api'
server = api.listen port

Log "Starting server on port #{ port }"

# Start sync
Sync = require "./sync"
Sync.init server
