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
  describe('DELETE /', function() {
    it('needs authentication', function(done) {
      request(app)
        .delete(endpoint + '/')
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('requires a list', function(done) {
      request(app)
        .delete(endpoint + '/')
        .set({'Authorization': 'Bearer ' + token.access_token})
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)        
          done()
        })
    })
    it('requires correct uuid syntax', function(done) {
      request(app)
        .delete(endpoint + '/')
        .set({'Authorization': 'Bearer ' + token.access_token})
        .send({lists: ['rekt']})
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should delete a list', function(done) {
      request(app)
        .delete(endpoint + '/')
        .set({'Authorization': 'Bearer ' + token.access_token})
        .send({lists: [listId]})
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should be deleted from the database', function(done) {
      request(app)
        .get(endpoint + '/' + listId)
        .set({'Authorization': 'Bearer ' + token.access_token})
        .expect(404)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should not delete a list belonging to another user', function(done) {
      request(app)
        .delete(endpoint + '/')
        .set({'Authorization': 'Bearer ' + token.access_token})
        .send({lists: [listId2]})
        .expect(404)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should not delete a list that does not exist', function(done) {
      request(app)
        .delete(endpoint + '/')
        .set({'Authorization': 'Bearer ' + token.access_token})
        .send({lists: ['38944917-a0fd-4e31-9c56-6c1f825bfa0c']})
        .expect(404)
        .end(function(err, res) {
          if (err) return done(err)
          assert.equal(res.body.items[0], '38944917-a0fd-4e31-9c56-6c1f825bfa0c', 'Not found list must be found.')
          done()
        })
    })
  })
})