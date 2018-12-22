const passport = require('passport')
const logger = require('../logger.js')
const Task = require('../models/task')
const ArchivedTask = require('../models/archivedtask')

const helpers = require('./helpers.js')
const archiveTasks = helpers.archiveTasks

const archive = require('express').Router()
archive.use(passport.authenticate('bearer', { session: false }))

archive.get('/', (req, res) => {
  ArchivedTask.findAll({
    where: {
      userId: req.user
    }
  })
    .then(data => {
      res.send(data)
    })
    .catch(err => {
      res.status(500).send(err)
    })
})
archive.post('/:listid', (req, res) => {
  const tasks = {}
  if (typeof req.body.tasks !== 'undefined') {
    tasks.tasks = req.body.tasks.join(',')
  }
  archiveTasks(tasks, req.user, req.params.listid)
    .then(tasks => {
      res.send({ message: 'Successfully archived tasks.', data: tasks })
    })
    .catch(err => {
      logger.error(
        {
          userId: req.user,
          listId: req.params.listId,
          err: err
        },
        'archive error'
      )
      res.status(err.code).send(err)
    })
})

module.exports = archive
