const express = require('express')
const config = require('./config')
const migrator = require('./lib/migrator')

const app = express()

// set headers for every request
app.disable('x-powered-by')
app.use(function(req, res, next) {
  res.setHeader('X-Frame-Options', 'SAMEORIGIN')
  res.setHeader('X-Content-Type-Options', 'nosniff')
  res.setHeader('X-XSS-Protection', '1; mode=block')
  next()
})

// only start the api once the db is ready
migrator.migrate().then(function() {
  app.use('/a', require('./lib/router.js'))
})
 
// the router routes stuff through this port
var port = config.port
app.listen(port, function() {
  console.log('listening on localhost:' + port)
})