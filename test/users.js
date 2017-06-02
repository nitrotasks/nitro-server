const assert = require('assert')
const request = require('supertest')
const endpoint = '/a/users'

describe('/users', function() {
  describe('POST /create', function() {
    it('should create a user', function(done) {
      request(app)
        .post(endpoint + '/create')
        .send({ username: 'newuser', password: 'secret' })
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should reject duplicate users', function(done) {
      request(app)
        .post(endpoint + '/create')
        .send({ username: 'test@nitrotasks.com', password: 'secret' })
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('needs parameters', function(done) {
      request(app)
        .post(endpoint + '/create')
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should fail if username or password are empty', function(done) {
      request(app)
        .post(endpoint + '/create')
        .send({ username: '', password: '' })
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
  })
  describe('DELETE /', function() {
    it('needs authentication', function(done) {
      request(app)
        .delete(endpoint)
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should delete a user', function(done) {
      request(app)
        .delete(endpoint)
        .set({'Authorization': 'Bearer ' + token.access_token})
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should be deleted', function(done) {
      request(app)
        .delete(endpoint)
        .set({'Authorization': 'Bearer ' + token.access_token})
        .expect(404)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })

  })
})