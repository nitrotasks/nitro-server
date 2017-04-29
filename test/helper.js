const express = require('express')
const migrator = require('../lib/migrator')
const request = require('supertest')
app = express()
token = null
token2 = null

before(function(done) {
  // clean db
  console.log('Creating DB...')
  migrator.migrate(true).then(function() {

    app.use('/a', require('../lib/router.js'))

    let promises = []

    // setup two basic users and get two access tokens
    promises.push(new Promise(function(resolve, reject) {
      request(app)
        .post('/a/users/create')
        .send({ username: 'test@nitrotasks.com', password: 'secret' })
        .end(function(err, data) {
          token = data.body

          // need to get an access token too
          request(app)
            .get('/a/auth/token/' + token.refresh_token)
            .end(function(err, data) {
              resolve()
              token.access_token = data.body.access_token
            })
        })
    }))
    promises.push(new Promise(function(resolve, reject) {
      request(app)
        .post('/a/users/create')
        .send({ username: 'test2@nitrotasks.com', password: 'secret' })
        .end(function(err, data) {
          token2 = data.body

          // need to get an access token too
          request(app)
            .get('/a/auth/token/' + token2.refresh_token)
            .end(function(err, data) {
              resolve()
              token2.access_token = data.body.access_token
            })
        })
    }))
    Promise.all(promises).then(function() {
      console.log('DB Created.\n')
      done()
    })
  })
})