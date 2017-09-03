const tasks = require('express').Router()
const passport = require('passport')
const User = require('../models/user')
const List = require('../models/list')
const Task = require('../models/task')

const fullTaskAttributes = ['id', 'name', 'type', 'notes', 'completed', 'updatedAt', 'createdAt']

const tasksDetails = function(fullDetails = false) {
  return function(req, res) {
    let listAttributes = ['id', 'name', 'notes', 'updatedAt', 'createdAt', 'order']
    let userAttributes = ['id', 'friendlyName', 'email']
    let taskModel = {
      model: Task,
      attributes: ['id', 'updatedAt', 'createdAt']
    }
    // if we mutate fullDetails, bad things seem to happen :|
    if (fullDetails || ('tasks' in req.query && req.query.tasks.length > 0))  {
      taskModel.attributes = fullTaskAttributes

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
    attributes: ['id', 'name', 'updatedAt', 'createdAt', 'notes', 'order'],
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
        
        const payload = {}
        const allowedUpdates = ['name', 'notes']
        allowedUpdates.forEach(function(key) {
          if (key in req.body) {
            payload[key] = req.body[key]
          }
        })
        // order has a special update
        if ('order' in req.body) {
          // makes sure same length
          if (list.order.length === req.body.order.length) {
            let shouldUpdate = true
            // then goes through all the keys and sees if they're the same
            list.order.forEach(function(key) {
              if (req.body.order.indexOf(key) === -1) {
                shouldUpdate = false
              }
            })
            if (shouldUpdate) {
              payload.order = req.body.order
            }
          }
        }
        list.update(payload).then(function(list) {
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
    attributes: ['id', 'order'],
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

        // pushes new tasks onto the end of the list order
        list.update({
          order: JSON.parse(JSON.stringify(list.order)).concat(result.map(function(item) {
            return item.id
          }))
        }).then(function(list) {
          res.send({
            message: 'Created Tasks.',
            tasks: result.map(function(item, key) {
              item.originalId = req.body.tasks[key].id
              return item
            })
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
tasks.patch('/:listid/tasks', passport.authenticate('bearer', {session: false}), function(req, res) {
  if (req.body
    && 'tasks' in req.body
    && Object.keys(req.body.tasks).length > 0) {
    List.findById(req.params.listid, {
      include: [
        {
          model: User,
          attributes: ['id'],
          where: {
            id: req.user
          }
        },
        {
          model: Task,
          attributes: fullTaskAttributes,
          where: {
            id: Object.keys(req.body.tasks)
          }
        }
      ]
    }).then(function(retrieved) {
      if (retrieved && retrieved.tasks.length === Object.keys(req.body.tasks).length) {
        const updateSingle = function(model) {
          return new Promise(function(resolve, reject) {
            const newData = req.body.tasks[model.id]
            if (model.updatedAt.getTime() < new Date(newData.updatedAt).getTime()) {
              const payload = {}
              const allowedUpdates = ['name', 'notes', 'type', 'completed']
              allowedUpdates.forEach(function(key) {
                if (key in newData) {
                  payload[key] = newData[key]
                }
              })
              // apply the updates
              model.update(payload).then(resolve).catch(reject)
            } else {
              resolve(model)
            }
          })
        }
        const promises = retrieved.tasks.map(function(task) {
          return updateSingle(task)
        })
        Promise.all(promises).then(function(data) {
          // set the update so the client can pick up on changes on this list
          retrieved.changed('updatedAt', true)
          retrieved.update({
            updatedAt: new Date()
          }).then(function(list) {
            res.send({message: 'Update Success', tasks: data})
          })
        }).catch(function(err) {
          console.warn(err)
          res.send({message: 'Internal Server Error'})
        })
      } else {
        const specifically = Object.keys(req.body.tasks)
        if (retrieved) {
          retrieved.tasks.forEach(function(item) {
            const index = specifically.indexOf(item.id)
            if (index > -1) {
              specifically.splice(index, 1)
            }
          })
        }
        res.status(404).send({
          message: 'Tasks could not be found.', 
          items: specifically,
        })
      }
    }).catch(function(err) {
      res.status(400).send({message: 'Invalid input syntax.'})
    })
  } else {
    res.status(400).send({message: 'Tasks not supplied or empty.'})
  }
})
tasks.delete('/:listid', passport.authenticate('bearer', {session: false}), function(req, res) {
  if (req.body
    && 'tasks' in req.body
    && req.body.tasks.length > 0) {
    List.findById(req.params.listid, {
      attributes: ['id', 'order'],
      include: [
        {
          model: User,
          attributes: ['id'],
          where: {
            id: req.user
          }
        },
        {
          model: Task,
          attributes: ['id'],
          where: {
            id: req.body.tasks
          }
        }
      ]
    }).then(function(retrieved) {
      if (retrieved && retrieved.tasks.length === req.body.tasks.length) {
        // remove item if it's found
        const newOrder = JSON.parse(JSON.stringify(retrieved.order)).filter(function(item) {
          return req.body.tasks.indexOf(item) === -1
        })
        retrieved.update({
          order: newOrder
        }).then(function() {
          Task.destroy({
            where: {
              id: req.body.tasks
            }
          }).then(function(data) {
            res.send({message: 'Successfully deleted tasks.', data: req.body.tasks})
          })
        }).catch(function(err) {
          console.log(err)
          res.status(500).send({message: 'An internal error occured.'})
        })
      } else {
        const specifically = req.body.tasks
        if (retrieved) {
          retrieved.tasks.forEach(function(item) {
            const index = specifically.indexOf(item.id)
            if (index > -1) {
              specifically.splice(index, 1)
            }
          })
        }
        res.status(404).send({
          message: 'Tasks could not be found.', 
          items: specifically,
        })
      }
    }).catch(function(err) {
      res.status(400).send({message: 'Invalid input syntax.'})
    })
  } else {
    res.status(400).send({message: 'Tasks not supplied or empty.'})
  }
})
module.exports = tasks