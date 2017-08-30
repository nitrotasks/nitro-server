const express = require('express')
const config = require('./config/config.js')
const migrator = require('./lib/migrator')
const compression = require('compression')

const app = express()

// set headers for every request
app.disable('x-powered-by')
app.use(compression({threshold: 200}))
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
  app.use('/a', require('./lib/router.js'))

  // static index routing
	app.use('/', express.static(config.dist))
  app.get('/', cb)
	app.get('/*', cb)
})
 
// the router routes stuff through this port
var port = config.port
app.listen(port, function() {
  console.log('listening on localhost:' + port)
})