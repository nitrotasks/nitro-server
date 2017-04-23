const assert = require('assert')
const request = require('supertest')
const endpoint = '/a/users/'

describe('users', function() {
  describe('/create', function() {
    it('should create a user', function(done) {
      request(app)
        .post(endpoint + '/create')
        .send({ username: 'testuser', password: 'secret' })
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should fail if no parameters are supplied', function(done) {
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
})