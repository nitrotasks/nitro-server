const passport = require('passport')
const Task = require('../models/task')
const ArchivedTask = require('../models/archivedtask')

const helpers = require('./helpers.js')
const tasksDetails = helpers.tasksDetails

const archive = require('express').Router()
archive.use(passport.authenticate('bearer', { session: false }))

archive.get('/', (req, res) => {
  res.send('whatever')
})
archive.post('/:listid', (req, res) => {
  tasksDetails(true, req.query, req.user, req.params.listid).then(data => {
    // For each of these tasks, add to archive list for both users
    const promises = []
    data.users.forEach((user) => {
      const adding = data.toJSON().tasks.map(function(item) {
        return {
          data: JSON.stringify(item),
          userId: user.id
        }
      })
      promises.push(ArchivedTask.bulkCreate(adding, {
        validate: true
      }))
    })
    const tasks = data.tasks.map(task => task.id)
    Promise.all(promises).then(() => {
      // Task.destroy
      res.send('whatever')
    }).catch(err => {
      res.status(500).send(err)
    })

    // Then delete from list
    // Task.destroy
  }).catch(err => {
    console.log(err)
    res.status(err.code).send(err)
  })
})

module.exports = archive