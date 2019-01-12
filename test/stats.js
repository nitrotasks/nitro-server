const assert = require('assert')
const request = require('supertest')
const endpoint = '/a/stats'

const authToken = () => ({
  Authorization: 'Bearer ' + token.access_token
})

describe('/stats', function() {
  describe('GET /', function() {
    it('needs authentication', function(done) {
      request(app)
        .get(endpoint)
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should return stats', function(done) {
      request(app)
        .get(endpoint)
        .set(authToken())
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          Object.keys(res.body.counts).forEach(key => {
            assert.notEqual(res.body.counts[key], null)
          })
          done()
        })
    })
  })
})
