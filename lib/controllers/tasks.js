const tasks = require('express').Router()
const passport = require('passport')
const User = require('../models/user')
const List = require('../models/list')
const Task = require('../models/task')

const tasksDetails = function(fullDetails = false) {
  return function(req, res) {
    let listAttributes = ['id', 'name', 'notes', 'updatedAt', 'createdAt']
    let userAttributes = ['id', 'friendlyName', 'email']
    let taskModel = {
      model: Task,
      attributes: ['id', 'updatedAt', 'createdAt']
    }
    if ('tasks' in req.query && req.query.tasks.length > 0) {
      fullDetails = true
    }
    if (fullDetails) {
      taskModel.attributes = ['id', 'name', 'notes', 'updatedAt', 'createdAt']

      if ('tasks' in req.query) {
        listAttributes = []
        userAttributes = []

        options = req.query.tasks.split(',')
        taskModel.where = {
          id: options
        }
      }
    }
    const query = {
      attributes: listAttributes,
      include: [
        {
          model: User,
          attributes: userAttributes,
          where: {
            id: req.user
          }
        },
        taskModel
      ]
    }
    List.findById(req.params.listid, query).then(function(list) {
      if (list) {
        if ('tasks' in req.query) {
          res.send(list.toJSON().tasks)
        } else {
          res.send(list)
        }
      } else {
        res.status(404).send({message: 'List could not be found.'})
      }
    }).catch(function(err) {
      res.status(400).send({message: 'Invalid input syntax.'})
    })
  }
}

tasks.get('/:listid', passport.authenticate('bearer', {session: false}), tasksDetails(false))
tasks.get('/:listid/tasks', passport.authenticate('bearer', {session: false}), tasksDetails(true))

tasks.patch('/:listid', passport.authenticate('bearer', {session: false}), function(req, res) {
  const query = {
    attributes: ['id', 'name', 'updatedAt', 'createdAt'],
    include: [
      {
        model: User,
        attributes: ['id', 'friendlyName', 'email'],
        where: {
          id: req.user
        }
      }
    ]
  }
  List.findById(req.params.listid, query).then(function(list) {
    if (list) {
      if (list.updatedAt.getTime() < new Date(req.body.updatedAt).getTime()) {
        list.update({
          name: req.body.name,
          notes: req.body.notes,
        }).then(function(list) {
          res.send(list)
        }).catch(function(err) {
          console.warn(err)
          res.status(500).send({message: 'Internal server error.'})
        })
      } else {
        res.send(list.toJSON())
      }
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
      // todo: proper validation?
      const adding = req.body.tasks.map(function(item) {
        return {
          name: item.name,
          notes: item.notes,
          // must be specified here, otherwise the relation isn't made
          listId: list.id
        }
      })
      // they have permission to add into that list
      Task.bulkCreate(adding, {
        validate: true
      }).then(function(done) {
        const result = JSON.parse(JSON.stringify(done))
        res.send({
          message: 'Created Tasks.',
          tasks: result.map(function(item, key) {
            item.originalId = req.body.tasks[key].id
            return item
          })
        })
      }).catch(function(err) {
        res.status(400).send(err)
      })
    } else {
      res.status(404).send({message: 'List could not be found.'})
    }
  }).catch(function(err) {
    res.status(400).send({message: 'Invalid input syntax.'})
  })
})
module.exports = tasks