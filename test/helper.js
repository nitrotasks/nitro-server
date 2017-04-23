const express = require('express')
const migrator = require('../lib/migrator')
const request = require('supertest')
app = express()
token = null

before(function(done) {
  // clean db
  console.log('Creating DB...')
  migrator.migrate(true).then(function() {

    app.use('/a', require('../lib/router.js'))

    // setup a basic user
    request(app)
      .post('/a/users/create')
      .send({ username: 'test@nitrotasks.com', password: 'secret' })
      .end(function(err, data) {
        token = data.body

        // need to get an access token too
        request(app)
          .post('/a/auth/token')
          .send({refresh_token: token.refresh_token})
          .end(function(err, data) {
            console.log('DB Created.\n')

            token.access_token = data.body.access_token
            done()
          })
      })
  })
})