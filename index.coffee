
# Handles all the requests...

# Start api
api = require './app/api'
server = api.listen( 443 )

# Start sync
Sync = require "./app/sync"
Sync.init( server )
