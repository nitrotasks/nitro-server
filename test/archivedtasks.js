const assert = require('assert')
const request = require('supertest')
const endpoint = '/a/archive'

let listId = null
let taskId = [null, null, null]
describe('/archive', function() {
  before(function(done) {
    request(app)
      .post('/a/lists')
      .send({ name: 'A archive list' })
      .set({ Authorization: 'Bearer ' + token.access_token })
      .end(function(err, res) {
        listId = res.body.id

        request(app)
          .post('/a/lists/' + listId)
          .send({
            tasks: [
              { name: 'archive0' },
              { name: 'archive1' },
              { name: 'archive2' }
            ]
          })
          .set({ Authorization: 'Bearer ' + token.access_token })
          .expect(200)
          .end(function(err, res) {
            if (err) return done(err)
            taskId[0] = res.body.tasks[0].id
            taskId[1] = res.body.tasks[1].id
            taskId[2] = res.body.tasks[2].id
            done()
          })
      })
  })
  describe('POST /:listid', function() {
    it('needs authentication', function(done) {
      request(app)
        .post(endpoint + '/' + listId)
        .expect(400)
        .end((err, res) => {
          if (err) return done(err)
          done()
        })
    })
    it('should archive a task', done => {
      request(app)
        .post(endpoint + '/' + listId)
        .set({ Authorization: 'Bearer ' + token.access_token })
        .end((err, res) => {
          if (err) return done(err)
          done()
        })
    })
  })
  describe('GET /', function() {
    it('needs authentication', function(done) {
      request(app)
        .get(endpoint)
        .expect(400)
        .end((err, res) => {
          if (err) return done(err)
          done()
        })
    })
  })
  after(function(done) {
    request(app)
      .delete('/a/lists/')
      .set({ Authorization: 'Bearer ' + token.access_token })
      .send({lists: [listId]})
      .end(function(err, res) {
        if (err) return done(err)
        done()
      })
  })
})
