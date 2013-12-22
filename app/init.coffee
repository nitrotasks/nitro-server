config  = require './config'
Log     = require './utils/log'
connect = require './controllers/connect'
router  = require './controllers/router'
# sockets = require './controllers/sockets'

###
 * If this file is required by another, then it will put the app into
 * debug mode and just return the router.
###

if module.parent?
  global.DebugMode = true
  module.exports = router

log  = Log 'Info', 'green'
warn = Log 'Warning', 'red'

# Handle debug mode
global.DebugMode = off

# Enable debug mode if passed as argument
if '--debug' in process.argv
  global.DebugMode = on
  warn 'Running in debug mode!'

config.use if global.DebugMode then 'development' else 'production'

connect.init()

log "Starting server on port #{ config.port }"

# Start router
server = router.listen config.port

# Start sync
# sockets.init serve
