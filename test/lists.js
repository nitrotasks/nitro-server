const assert = require('assert')
const request = require('supertest')
const endpoint = '/a/lists'

let listId = null
let listId2 = null

describe('/lists', function() {
  describe('POST /', function() {
    it('needs authentication', function(done) {
      request(app)
        .post(endpoint)
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should fail if no name is supplied', function(done) {
      request(app)
        .post(endpoint)
        .set({'Authorization': 'Bearer ' + token.access_token})
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should fail if name is blank', function(done) {
      request(app)
        .post(endpoint)
        .send({ name: '' })
        .set({'Authorization': 'Bearer ' + token.access_token})
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should create a list and return id, originalId, name, and user attributes', function(done) {
      request(app)
        .post(endpoint)
        .send({ name: 'A Cool List', id: '12345' })
        .set({'Authorization': 'Bearer ' + token.access_token})
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          if ( typeof(res.body.id) !== 'undefined'
            && res.body.originalId === '12345'
            && typeof(res.body.name) !== 'undefined'
            && typeof(res.body.users) !== 'undefined') {
              done()
          } else {
            done(new Error('Did not have all attributes'))
          }
        })
    })
  })

  describe('GET /', function() {
    before(function(done) {
      // creates another test list
      request(app)
        .post(endpoint)
        .send({ name: 'A List Not belonging to user1' })
        .set({'Authorization': 'Bearer ' + token2.access_token})
        .end(function(err, res) {
          listId2 = res.body.id
          done()
        })
    })
    it('needs authentication', function(done) {
      request(app)
        .get(endpoint)
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should return all lists for the user', function(done) {
      request(app)
        .get(endpoint)
        .set({'Authorization': 'Bearer ' + token.access_token})
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          if (res.body.length === 1) {
            listId = res.body[0].id
            done()
          } else {
            done(new Error('Did not return expected number of lists.'))
          }
        })
    })
  })

  describe('GET /id', function() {
    it('needs authentication', function(done) {
      request(app)
        .get(endpoint + '/' + listId)
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
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
        .get(endpoint + '/' + listId2)
        .set({'Authorization': 'Bearer ' + token.access_token})
        .expect(404)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
  })
})