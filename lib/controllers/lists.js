const lists = require('express').Router()
const logger = require('../logger.js')
const tasks = require('./tasks')
const passport = require('passport')
const User = require('../models/user')
const List = require('../models/list')

const helpers = require('./helpers.js')
const archiveTasks = helpers.archiveTasks
const getListOrder = helpers.getListOrder
const appendToListOrder = helpers.appendToListOrder
const removeFromListOrder = helpers.removeFromListOrder
const filterByUser = helpers.filterByUser

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

  try {
    // max length for a STRING
    const name = req.body.name.substring(0, 255)
    const list = await List.create({
      name: name
    })
    const user = await User.findById(req.user)
    await list.addUser(user)
    await appendToListOrder(req.user, list.id)

    const foundList = await List.findById(list.id, query)
    const response = JSON.parse(JSON.stringify(foundList))
    response.originalId = req.body.id
    res.send(response)
  } catch (err) {
    logger.error(
      {
        userId: req.user,
        err: err
      },
      'POST lists'
    )
    res.status(500).send({ message: 'Internal Server Error' })
  }
})

lists.get('/', auth, async function(req, res) {
  const lists = await List.findAll({
    attributes: ['id', 'name', 'updatedAt', 'createdAt'],
    include: filterByUser(req.user)
  })
  const listOrder = (await getListOrder(req.user)).value
  if (listOrder.length === lists.length) {
    const listMap = new Map()
    lists.forEach((list, key) => {
      listMap.set(list.id, key)
    })

    // this kinda feels weird because we're mapping the actual objects
    // can possibly serialize if this has weird sideeffects
    const listsInOrder = listOrder.map(i => {
      return lists[listMap.get(i)]
    })
    res.send(listsInOrder)
  } else {
    // somehow got out of sync, rely on client to fix it
    res.send(lists)
  }
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
    logger.error(
      {
        userId: req.user,
        err: err
      },
      'DELETE lists'
    )
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
        await removeFromListOrder(req.user, list.id)
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
      logger.error(
        {
          userId: req.user,
          err: err
        },
        'DELETE lists'
      )
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
