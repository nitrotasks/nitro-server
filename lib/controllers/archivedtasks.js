const passport = require('passport')
const Task = require('../models/task')
const ArchivedTask = require('../models/archivedtask')

const helpers = require('./helpers.js')
const tasksDetails = helpers.tasksDetails

const archive = require('express').Router()
archive.use(passport.authenticate('bearer', { session: false }))

archive.get('/', (req, res) => {
  ArchivedTask.findAll({
    where: {
      userId: req.user
    }
  }).then(data => {
    res.send(data)
  }).catch(err => {
    res.status(500).send(err)
  })
})
archive.post('/:listid', (req, res) => {
  const tasks = {}
  if (typeof req.body.tasks !== 'undefined') {
    tasks.tasks = req.body.tasks.join(',')
  }
  tasksDetails(true, tasks, req.user, req.params.listid).then(list => {
    // For each of these tasks, add to archive list for both users
    const promises = []
    list.users.forEach((user) => {
      const adding = list.toJSON().tasks.map(function(item) {
        return {
          data: JSON.stringify(item),
          userId: user.id
        }
      })
      promises.push(ArchivedTask.bulkCreate(adding, {
        validate: true
      }))
    })
    const tasks = list.tasks.map(task => task.id)
    Promise.all(promises).then(() => {
      // remove item if it's found
      const newOrder = JSON.parse(JSON.stringify(list.order)).filter(function(item) {
        return tasks.indexOf(item) === -1
      })
      list.update({
        order: newOrder
      }).then(function() {
        Task.destroy({
          where: {
            id: tasks
          }
        }).then(function() {
          res.send({message: 'Successfully archived tasks.', data: tasks})
        })
      })
    })
  }).catch(err => {
    res.status(err.code).send(err)
  })
})

module.exports = archive