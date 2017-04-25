const lists = require('express').Router()
const passport = require('passport')
const User = require('../models/user')
const List = require('../models/list')
const Task = require('../models/task')

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
            res.send(list)
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


lists.get('/:listid', passport.authenticate('bearer', {session: false}), function(req, res) {
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
  })
})

module.exports = lists