const assert = require('assert')
const request = require('supertest')
const endpoint = '/a/lists'

let listId = null
let taskId = null
let taskId2 = null

describe('/lists/:listid', function() {
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
        {name: 'Another brand new task.'},
        {name: 'Another brand new taskzhgzg.'}
        ]})
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
          assert(typeof(res.body.name) !== 'undefined')
          assert(typeof(res.body.notes) !== 'undefined')
          assert(typeof(res.body.users) !== 'undefined')
          assert(typeof(res.body.tasks) !== 'undefined')
          assert(res.body.tasks.length === 3)
          assert('id' in res.body.tasks[0])
          taskId = res.body.tasks[0].id
          taskId2 = res.body.tasks[1].id
          taskId3 = res.body.tasks[2].id
          assert('updatedAt' in res.body.tasks[0])
          assert('createdAt' in res.body.tasks[0])
          assert(typeof(res.body.updatedAt) !== 'undefined')
          assert(typeof(res.body.createdAt) !== 'undefined')
          assert(typeof(res.body.order) !== 'undefined', 'has order')
          assert.equal(res.body.order.length, res.body.tasks.length, 'tasks order matches tasks length')
          done()
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
  describe('GET /tasks (all tasks)', function() {
    it('needs authentication', function(done) {
      request(app)
        .get(endpoint + '/' + listId + '/tasks')
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should return list with users and full tasks', function(done) {
      request(app)
        .get(endpoint + '/' + listId + '/tasks')
        .set({'Authorization': 'Bearer ' + token.access_token})
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          assert(typeof(res.body.name) !== 'undefined')
          assert(typeof(res.body.notes) !== 'undefined')
          assert(typeof(res.body.users) !== 'undefined')
          assert(typeof(res.body.tasks) !== 'undefined')
          assert(res.body.tasks.length === 3)
          assert('id' in res.body.tasks[0])
          assert('name' in res.body.tasks[0])
          assert('notes' in res.body.tasks[0])
          assert('updatedAt' in res.body.tasks[0])
          assert('createdAt' in res.body.tasks[0])
          assert(typeof(res.body.updatedAt) !== 'undefined')
          assert(typeof(res.body.createdAt) !== 'undefined')
          done()
        })
    })
  })
  describe('GET /?tasks (selection of tasks)', function() {
    it('needs authentication', function(done) {
      request(app)
        .get(endpoint + '/' + listId + '/?tasks=' + taskId)
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('requires correct uuid syntax', function(done) {
      request(app)
        .get(endpoint + '/' + listId + '/?tasks=rekt')
        .set({'Authorization': 'Bearer ' + token.access_token})
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should get the full task details', function(done) {
      request(app)
        .get(endpoint + '/' + listId + '/?tasks=' + taskId)
        .set({'Authorization': 'Bearer ' + token.access_token})
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          assert(typeof(res.body[0].id) !== 'undefined', 'has id')
          assert(typeof(res.body[0].name) !== 'undefined', 'has name')
          assert(typeof(res.body[0].notes) !== 'undefined', 'has notes')
          assert(typeof(res.body[0].updatedAt) !== 'undefined', 'has updatedAt')
          assert(typeof(res.body[0].createdAt) !== 'undefined', 'has createdAt')
          done()
        })
    })
    it('should get multiple tasks', function(done) {
      request(app)
        .get(endpoint + '/' + listId + '/?tasks=' + taskId + ',' + taskId2)
        .set({'Authorization': 'Bearer ' + token.access_token})
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          assert(res.body.length === 2)
          done()
        })
    })
    it('should not return a task belonging to another user', function(done) {
      request(app)
        .get(endpoint + '/' + listId + '/?tasks=' + taskId)
        .set({'Authorization': 'Bearer ' + token2.access_token})
        .expect(404)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should not return a task if does not exist', function(done) {
      request(app)
        .get(endpoint + '/' + listId + '/?tasks=38944917-a0fd-4e31-9c56-6c1f825bfa0c')
        .set({'Authorization': 'Bearer ' + token.access_token})
        .expect(404)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should get tasks that do exist if one not found', function(done) {
      request(app)
        .get(endpoint + '/' + listId + '/?tasks=' + taskId + ',38944917-a0fd-4e31-9c56-6c1f825bfa0c')
        .set({'Authorization': 'Bearer ' + token.access_token})
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          assert(res.body.length === 1)
          done()
        })
    })
  })
  describe('PATCH /' , function() {
    it('needs authentication', function(done) {
      request(app)
        .patch(endpoint + '/' + listId)
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('requires a list', function(done) {
      request(app)
        .patch(endpoint + '/')
        .set({'Authorization': 'Bearer ' + token.access_token})
        .expect(404)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('requires correct uuid syntax', function(done) {
      request(app)
        .patch(endpoint + '/notacorrectuuid')
        .set({'Authorization': 'Bearer ' + token.access_token})
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should update a list and return all required attributes', function(done) {
      request(app)
        .patch(endpoint + '/' + listId)
        .set({'Authorization': 'Bearer ' + token.access_token})
        .send({name: 'A different name.', notes: 'A different notes.', updatedAt: new Date()})
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          assert(typeof(res.body.name) !== 'undefined', 'has name')
          assert(typeof(res.body.notes) !== 'undefined', 'has notes')
          assert(typeof(res.body.order) !== 'undefined', 'has order')
          assert(typeof(res.body.users) !== 'undefined', 'has users')
          assert(typeof(res.body.updatedAt) !== 'undefined', 'has updatedAt')
          assert(typeof(res.body.createdAt) !== 'undefined', 'has createdAt')

          request(app)
            .get(endpoint + '/' + listId)
            .set({'Authorization': 'Bearer ' + token.access_token})
            .end(function(err, res) {
              if (err) return done(err)
              assert.equal(res.body.name, 'A different name.')
              assert.equal(res.body.notes, 'A different notes.')
              done()
            })
        })
    })
    let currentOrder = null
    it('should ignore the update if paramater is not specified', function(done) {
      request(app)
        .patch(endpoint + '/' + listId)
        .set({'Authorization': 'Bearer ' + token.access_token})
        .send({name: 'A different yoho.', updatedAt: new Date()})
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          currentOrder = res.body.order
          assert.equal(res.body.name, 'A different yoho.')
          assert.equal(res.body.notes, 'A different notes.')
          done()
        })
    })
    it('should update order', function(done) {
      request(app)
        .patch(endpoint + '/' + listId)
        .set({'Authorization': 'Bearer ' + token.access_token})
        .send({order: currentOrder.reverse(), updatedAt: new Date()})
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          assert.equal(JSON.stringify(res.body.order), JSON.stringify(currentOrder))
          done()
        })
    })
    it('should not order if different length', function(done) {
      const newOrder = JSON.parse(JSON.stringify(currentOrder))
      newOrder.push(listId)
      request(app)
        .patch(endpoint + '/' + listId)
        .set({'Authorization': 'Bearer ' + token.access_token})
        .send({order: newOrder, updatedAt: new Date()})
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          assert.equal(JSON.stringify(res.body.order), JSON.stringify(currentOrder))
          done()
        })
    })
    it('should not order if different elements', function(done) {
      let lastOrder = JSON.stringify(currentOrder)
      currentOrder[0] = listId
      request(app)
        .patch(endpoint + '/' + listId)
        .set({'Authorization': 'Bearer ' + token.access_token})
        .send({order: currentOrder, updatedAt: new Date()})
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          assert.equal(JSON.stringify(res.body.order), lastOrder)
          done()
        })
    })
    it('should not update a list if it has been updated more recently', function(done) {
      request(app)
        .patch(endpoint + '/' + listId)
        .set({'Authorization': 'Bearer ' + token.access_token})
        .send({name: 'NO UPDATE', notes: 'NO NOTES', updatedAt: new Date(0)})
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)

          request(app)
            .get(endpoint + '/' + listId)
            .set({'Authorization': 'Bearer ' + token.access_token})
            .end(function(err, res) {
              if (err) return done(err)
              assert.equal(res.body.name, 'A different yoho.')
              assert.equal(res.body.notes, 'A different notes.')
              done()
            })
        })
    })
    it('should not update a list that belongs to someone else', function(done) {
      request(app)
        .patch(endpoint + '/' + listId)
        .set({'Authorization': 'Bearer ' + token2.access_token})
        .send({name: 'A different name.', notes: 'A different notes.'})
        .expect(404)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
  })
  describe('PATCH /tasks' , function() {
    it('needs authentication', function(done) {
      request(app)
        .patch(endpoint + '/' + listId + '/tasks')
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
  })
  describe('DELETE /' , function() {
    it('needs authentication', function(done) {
      request(app)
        .delete(endpoint + '/' + listId)
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('requires a task', function(done) {
      request(app)
        .delete(endpoint + '/' + listId)
        .set({'Authorization': 'Bearer ' + token.access_token})
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)        
          done()
        })
    })
    it('requires correct uuid syntax', function(done) {
      request(app)
        .delete(endpoint + '/' + listId)
        .set({'Authorization': 'Bearer ' + token.access_token})
        .send({tasks: ['rekt']})
        .expect(400)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should not delete a task belonging to another user', function(done) {
      request(app)
        .delete(endpoint + '/' + listId)
        .set({'Authorization': 'Bearer ' + token2.access_token})
        .send({tasks: [taskId, taskId2]})
        .expect(404)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should delete a task', function(done) {
      request(app)
        .delete(endpoint + '/' + listId)
        .set({'Authorization': 'Bearer ' + token.access_token})
        .send({tasks: [taskId, taskId2]})
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should be deleted from the database', function(done) {
      request(app)
        .get(endpoint + '/' + listId + '?tasks=' + taskId + ',' + taskId2)
        .set({'Authorization': 'Bearer ' + token.access_token})
        .expect(404)
        .end(function(err, res) {
          if (err) return done(err)
          done()
        })
    })
    it('should return exact tasks that do not exist', function(done) {
      request(app)
        .delete(endpoint + '/' + listId)
        .set({'Authorization': 'Bearer ' + token.access_token})
        .send({tasks: [taskId3, '38944917-a0fd-4e31-9c56-6c1f825bfa0c']})
        .expect(404)
        .end(function(err, res) {
          if (err) return done(err)
          assert.equal(res.body.items[0], '38944917-a0fd-4e31-9c56-6c1f825bfa0c', 'Not found task must be found.')
          done()
        })
    })
  })
})