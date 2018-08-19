const lists = require('express').Router()
const tasks = require('./tasks')
const passport = require('passport')
const User = require('../models/user')
const List = require('../models/list')

const helpers = require('./helpers.js')
const archiveTasks = helpers.archiveTasks

const auth = passport.authenticate('bearer', { session: false })

lists.use('/', tasks)

lists.post('/', auth, async function(req, res) {
  const query = {
    attributes: ['id', 'name', 'notes', 'createdAt', 'updatedAt', 'order'],
    include: {
      model: User,
      attributes: ['id', 'friendlyName', 'email']
    }
  }

  if (!req.body || !('name' in req.body) || req.body.name === '') {
    return res.status(400).send({ message: 'Name was not supplied.' })
  }
  if (req.body.name.slice(0, 9) === 'nitrosys-') {
    return res
      .status(403)
      .send({ message: 'Not allowed to create system lists.' })
  }

  const list = await List.create({
    name: req.body.name
  })
  const user = await User.findById(req.user)
  await list.addUser(user)
  const foundList = await List.findById(list.id, query)
  const response = JSON.parse(JSON.stringify(foundList))
  response.originalId = req.body.id
  res.send(response)
})

lists.get('/', auth, async function(req, res) {
  const query = {
    attributes: ['id', 'name', 'updatedAt', 'createdAt'],
    include: {
      model: User,
      attributes: [],
      where: {
        id: req.user
      }
    }
  }
  const lists = await List.findAll(query)
  res.send(lists)
})

lists.delete('/', auth, async function(req, res) {
  if (!req.body || !('lists' in req.body) || req.body.lists.length === 0) {
    return res.status(400).send({ message: 'Lists not supplied or empty.' })
  }
  let retrieved = null
  try {
    retrieved = await List.findAll({
      where: {
        id: req.body.lists
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
    })
  } catch (err) {
    return res.status(400).send({ message: 'Invalid input syntax.' })
  }

  let systemCheck = false
  retrieved.forEach(list => {
    if (list.name.slice(0, 9) === 'nitrosys-') {
      systemCheck = true
    }
  })
  if (systemCheck) {
    return res
      .status(403)
      .send({ message: 'Not allowed to delete system lists.' })
  }

  if (retrieved.length === req.body.lists.length) {
    try {
      // archive all the tasks
      for (let list of retrieved) {
        await archiveTasks({}, req.user, list.id)
      }
      await List.destroy({
        where: {
          id: req.body.lists
        }
      })
      res.send({
        message: 'Successfully deleted lists.',
        data: req.body.lists
      })
    } catch (err) {
      console.error(err)
      res.status(500).send({ message: 'An internal error occured.' })
    }
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
      items: specifically
    })
  }
})

module.exports = lists
