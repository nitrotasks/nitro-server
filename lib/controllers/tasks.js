const tasks = require('express').Router()
const passport = require('passport')
const User = require('../models/user')
const List = require('../models/list')
const Task = require('../models/task')

tasks.get('/:listid', passport.authenticate('bearer', {session: false}), function(req, res) {
  const query = {
    attributes: ['id', 'name'],
    include: [
      {
        model: User,
        attributes: ['id', 'friendlyName', 'email'],
        where: {
          id: req.user
        }
      },
      {
        model: Task,
      }
    ]
  }
  List.findById(req.params.listid, query).then(function(list) {
    if (list) {
      res.send(list)
    } else {
      res.status(404).send({message: 'List could not be found.'})
    }
  }).catch(function(err) {
    res.status(400).send({message: 'Invalid input syntax.'})
  })
})

tasks.post('/:listid', passport.authenticate('bearer', { session: false }), function(req, res) {
  const query = {
    attributes: ['id'],
    include: [
      {
        model: User,
        attributes: ['id'],
        where: {
          id: req.user
        }
      }
    ]
  }
  List.findById(req.params.listid, query).then(function(list) {
    if (list) {
      // they have permission to add into that list
      Task.bulkCreate(req.body.tasks, {
        validate: true
      }).then(function(done) {
        res.send({message: 'Created Tasks.', tasks: done})
      }).catch(function(err) {
        res.error(400).send(err)
      })
    } else {
      res.status(404).send({message: 'List could not be found.'})
    }
  }).catch(function(err) {
    res.status(400).send({message: 'Invalid input syntax.'})
  })
})

module.exports = tasks