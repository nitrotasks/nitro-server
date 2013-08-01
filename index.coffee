
# Handle debug mode
global.DebugMode = off

# Enable debug mode if passed as argument
if '--debug' in process.argv
  global.DebugMode = on
  console.warn '\u001b[31m> Running in debug mode!\u001b[0m'

# Port 443 should be piped to 8080
port = 8080

# Start api
api = require './app/api'
server = api.listen port

console.log "\u001b[34m> Starting server on port #{ port }\u001b[0m"

# Start sync
Sync = require "./app/sync"
Sync.init server
