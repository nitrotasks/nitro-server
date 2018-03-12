const http = require('http')
const express = require('express')
const config = require('./config/config.js')
const migrator = require('./lib/migrator')
const compression = require('compression')
const WebSocket = require('ws')
const socketController = require('./lib/controllers/websockets.js')

const app = express()
const server = http.createServer(app)

// set headers for every request
app.disable('x-powered-by')
if (config.dist !== false) {
  app.use(compression({threshold: 200}))
}
app.use(function(req, res, next) {
  res.setHeader('X-Frame-Options', 'SAMEORIGIN')
  res.setHeader('X-Content-Type-Options', 'nosniff')
  res.setHeader('X-XSS-Protection', '1; mode=block')
  next()
})

const cb = function(req, res) {
  res.sendFile(config.dist + '/index.html')
}

// only start the api once the db is ready
migrator.migrate().then(function() {
  if (config.dist !== false) {
    app.use('/a', require('./lib/router.js'))

    // static index routing
    app.use('/', express.static(config.dist))
    app.get('/', cb)
    app.get('/*', cb)

  // if we turn off the dist routing, we're only hosting API
  } else {
    app.use('/', require('./lib/router.js'))
  }

})

const wss = new WebSocket.Server({server})

wss.on('connection', socketController.connection)
 
// the router routes stuff through this port
var port = config.port
server.listen(port, function() {
  console.log('listening on localhost:' + port)
})