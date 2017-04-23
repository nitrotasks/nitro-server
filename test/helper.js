const express = require('express')
const migrator = require('../lib/migrator')
app = express()

before(function() {
  // clean db
  console.log('Creating DB...\n')
  migrator.migrate(true)

  app.use('/a', require('../lib/router.js'))
})