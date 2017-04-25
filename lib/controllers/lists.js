const lists = require('express').Router()
const passport = require('passport')
const User = require('../models/user')
const List = require('../models/list')
const Task = require('../models/task')

const createAttributes = {
  attributes: ['id', 'name'],
  include: {
    model: User,
    attributes: ['id', 'friendlyName', 'email']
  }
}

lists.post('/', passport.authenticate('bearer', { session: false }), function(req, res) {
  if (req.body
    && 'name' in req.body
    && req.body.name !== '') {
    List.create({
      name: req.body.name,
      userId: req.user
    }).then(function(list) {
      User.findById(req.user).then(function(user) {
        list.addUser(user).then(function() {
          List.findById(list.id, createAttributes).then(function(list) {
            res.send(list)
          })
        })
      })
    })
  } else {
    res.status(400).send({message: 'Name was not supplied.'})
  }
})

const getAttributes = {
  attributes: ['id', 'name'],
  include: {
    model: User,
    attributes: [],
  }
}


lists.get('/', passport.authenticate('bearer', { session: false }), function(req, res) {
  getAttributes.include.where = {
    id: req.user
  }
  List.findAll(getAttributes).then(function(lists) {
    res.send(lists)
  })
})

const getSingleAttributes = {
  attributes: ['id', 'name'],
  include: [
    {
      model: User,
      attributes: ['id', 'friendlyName', 'email']
    },
    {
      model: Task,
    }
  ]
}

lists.get('/:listid', passport.authenticate('bearer', {session: false}), function(req, res) {
  getSingleAttributes.include[0].where = {
    id: req.user
  }
  List.findById(req.params.listid, getSingleAttributes).then(function(list) {
    if (list) {
      res.send(list)
    } else {
      res.status(404).send({message: 'List could not be found.'})
    }
  })
})

module.exports = lists