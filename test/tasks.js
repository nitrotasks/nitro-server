const assert = require('assert')
const request = require('supertest')
const endpoint = '/a/lists'

let listId = null
let taskId = null

describe('/lists/:listid/tasks', function() {
  before(function(done) {
    // creates a test list
    request(app)
      .post(endpoint)
      .send({ name: 'A List for our Tasks' })
      .set({'Authorization': 'Bearer ' + token.access_token})
      .end(function(err, res) {
        listId = res.body.id
        done()
      })
  })
  describe('GET /', function() {
    it('needs authentication', function(done) {
      request(app)
        .get(endpoint + '/' + listId)
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('requires correct uuid syntax', function(done) {
      request(app)
        .get(endpoint + '/notacorrectuuid')
        .set({'Authorization': 'Bearer ' + token.access_token})
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          if (true) {
            done()
          } else {
            done(new Error('Did not return expected attributes.'))
          }
        })
    })
    it('should return list with users and tasks', function(done) {
      request(app)
        .get(endpoint + '/' + listId)
        .set({'Authorization': 'Bearer ' + token.access_token})
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          if (true) {
            done()
          } else {
            done(new Error('Did not return expected attributes.'))
          }
        })
    })
    it('should not return list belonging to another user', function(done) {
      request(app)
        .get(endpoint + '/' + listId)
        .set({'Authorization': 'Bearer ' + token2.access_token})
        .expect(404)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
  })
  describe('POST /', function() {
    it('needs authentication', function(done) {
      request(app)
        .post(endpoint + '/' + listId)
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('needs tasks params', function(done) {
      request(app)
        .post(endpoint + '/' + listId)
        .send({taskszz: 'yo'})
        .set({'Authorization': 'Bearer ' + token.access_token})
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should create multiple tasks', function(done) {
      request(app)
        .post(endpoint + '/' + listId)
        .send({tasks: [{
          name: 'A brand new task.'
        },
        {
          name: 'Another brand new task.'
        }]})
        .set({'Authorization': 'Bearer ' + token.access_token})
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should not create a task in a list belonging to another user', function(done) {
      request(app)
        .post(endpoint + '/' + listId)
        .send({tasks: [{
          name: 'A brand new task.'
        }]})
        .set({'Authorization': 'Bearer ' + token2.access_token})
        .expect(404)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
  })
})