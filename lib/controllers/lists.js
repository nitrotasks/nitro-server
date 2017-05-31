const lists = require('express').Router()
const tasks = require('./tasks')
const passport = require('passport')
const User = require('../models/user')
const List = require('../models/list')
const Task = require('../models/task')

lists.use('/', tasks)

lists.post('/', passport.authenticate('bearer', { session: false }), function(req, res) {
  const query = {
    attributes: ['id', 'name'],
    include: {
      model: User,
      attributes: ['id', 'friendlyName', 'email']
    }
  }

  if (req.body
    && 'name' in req.body
    && req.body.name !== '') {
    List.create({
      name: req.body.name,
      userId: req.user
    }).then(function(list) {
      User.findById(req.user).then(function(user) {
        list.addUser(user).then(function() {
          List.findById(list.id, query).then(function(list) {
            const response = JSON.parse(JSON.stringify(list))
            response.originalId = req.body.id
            res.send(response)
          })
        })
      })
    })
  } else {
    res.status(400).send({message: 'Name was not supplied.'})
  }
})

lists.get('/', passport.authenticate('bearer', { session: false }), function(req, res) {
  const query = {
    attributes: ['id', 'name'],
    include: {
      model: User,
      attributes: [],
      where: {
        id: req.user
      }
    }
  }
  List.findAll(query).then(function(lists) {
    res.send(lists)
  })
})

lists.delete('/', passport.authenticate('bearer', {session: false}), function(req, res) {
  if (req.body
    && 'lists' in req.body
    && req.body.lists.length > 0) {
    // TODO: Find all lists here and delete all of them
    List.findAll({
      where: {
        id: req.body.lists,
      },
      include: [
        {
          model: User,
          attributes: ['id'],
          where: {
            id: req.user
          }
        }
      ]
    }).then(function(retrieved) {
      if (retrieved.length === req.body.lists.length) {
        // TODO: maybe just do partial deletes???
        List.destroy({
          where: {
            id: req.body.lists
          }
        }).then(function(data) {
          res.send({message: 'Successfully deleted lists.', data: req.body.lists})
        }).catch(function(err) {
          console.log(err)
          res.status(500).send({message: 'An internal error occured.'})
        })
      } else {
        const specifically = req.body.lists
        retrieved.forEach(function(item) {
          const index = specifically.indexOf(item.id)
          if (index > -1) {
            specifically.splice(index, 1)
          }
        })
        res.status(404).send({
          message: 'Lists could not be found.', 
          items: specifically,
        })
      }
    }).catch(function(err) {
      res.status(400).send({message: 'Invalid input syntax.'})
    })
  } else {
    res.status(400).send({message: 'Lists not supplied or empty.'})
  }
})

module.exports = lists