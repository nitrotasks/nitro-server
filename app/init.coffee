config  = require './config'
Log     = require './utils/log'
connect = require './controllers/connect'
router  = require './controllers/router'
socket = require './controllers/socket'

log  = Log 'Info', 'green'
warn = Log 'Warning', 'red'

# Handle debug mode
DEBUG = global.DEBUG ?= off

# Enable debug mode if passed as argument
if '--debug' in process.argv
  DEBUG = on
  warn 'Running in debug mode!'

config.use if DEBUG then 'development' else 'production'

connect.init()

log "Starting server on port #{ config.port }"

# Start router
server = router.listen config.port

# Start sync
socket.init server

# Return router
module.exports = router
