const assert = require('assert')
const request = require('supertest')
const endpoint = '/a/archive'
const listEndpoint = '/a/lists'

let listId = null
let taskId = [null, null, null]
describe('/archive', function() {
  before(function(done) {
    request(app)
      .post(listEndpoint)
      .send({ name: 'A archive list' })
      .set({ Authorization: 'Bearer ' + token.access_token })
      .end(function(err, res) {
        listId = res.body.id

        request(app)
          .post(listEndpoint + '/' + listId)
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
        .send({ tasks: [taskId[0]] })
        .expect(200)
        .end((err, res) => {
          if (err) return done(err)
          request(app)
            .get(listEndpoint + '/' + listId)
            .set({ Authorization: 'Bearer ' + token.access_token })
            .expect(200)
            .end((err, res) => {
              if (err) return done(err)
              assert.equal(res.body.tasks.length, 2)
              done()
            })
        })
    })
    it('should archive the whole list if no tasks are specified', done => {
      request(app)
        .post(endpoint + '/' + listId)
        .set({ Authorization: 'Bearer ' + token.access_token })
        .expect(200)
        .end((err, res) => {
          if (err) return done(err)
          request(app)
            .get(listEndpoint + '/' + listId)
            .set({ Authorization: 'Bearer ' + token.access_token })
            .expect(200)
            .end((err, res) => {
              if (err) return done(err)
              assert.equal(res.body.tasks.length, 0)
              done()
            })
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
    it('should display archived tasks', function(done) {
      request(app)
        .get(endpoint)
        .set({ Authorization: 'Bearer ' + token.access_token })
        .end((err, res) => {
          if (err) return done(err)
          assert.equal(res.body.length, 3)
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
