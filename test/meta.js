const assert = require('assert')
const request = require('supertest')
const endpoint = '/a/meta'

// TODO: need to source this from the code itself?
const metaKeys = [
  'list-order',
  'settings-general',
  'settings-language',
  'test-key',
  'test-key-2'
]
const objectSample = { a: 1, b: true, c: '3' }
const arraySample = [1, true, '3']

const authToken = () => ({
  Authorization: 'Bearer ' + token.access_token
})

describe('/meta', function() {
  describe('POST /:key', function() {
    it('needs authentication', function(done) {
      request(app)
        .post(endpoint + '/test-key')
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should fail if there is no setting specified', function(done) {
      request(app)
        .post(endpoint)
        .set(authToken())
        .expect(404)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should be able to store a json object', function(done) {
      request(app)
        .post(endpoint + '/test-key')
        .set(authToken())
        .send(objectSample)
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should be able to store an json array', function(done) {
      request(app)
        .post(endpoint + '/test-key-2')
        .set(authToken())
        .send(arraySample)
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should not allow all keys', function(done) {
      request(app)
        .post(endpoint + '/not-a-real-key')
        .set(authToken())
        .send(objectSample)
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
  })
  describe('GET /:key', function() {
    it('should list available keys', function(done) {
      request(app)
        .get(endpoint)
        .set(authToken())
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          assert(
            res.body.keys.length === metaKeys.length,
            'has the correct amount of keys'
          )
          done()
        })
    })
    it('should get a json object back', function(done) {
      request(app)
        .get(endpoint + '/test-key')
        .set(authToken())
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          assert(JSON.stringify(res.body) === JSON.stringify(objectSample))
          done()
        })
    })
    it('should get a json array back', function(done) {
      request(app)
        .get(endpoint + '/test-key-2')
        .set(authToken())
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          assert(JSON.stringify(res.body) === JSON.stringify(arraySample))
          done()
        })
    })
    it('should return 400 if a key is not real', function(done) {
      request(app)
        .get(endpoint + '/not-a-real-key')
        .set(authToken())
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should return 404 if a key is not found', function(done) {
      request(app)
        .get(endpoint + '/settings-language')
        .set(authToken())
        .expect(404)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
  })
})
