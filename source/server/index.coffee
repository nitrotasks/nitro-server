log    = require('log_')('Server', 'blue')
router = require('./controllers/router')
socket = require('./controllers/socket')

startServer = (config) ->

  log "Starting server on port #{ config.port }"

  # Start router
  app = router.init(config)
  server = app.listen(config.port)

  # Start sync
  socket.init(server)

module.exports = startServer
