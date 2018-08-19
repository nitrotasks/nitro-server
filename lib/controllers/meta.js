const meta = require('express').Router()
const passport = require('passport')
const Meta = require('../models/meta')
const User = require('../models/user')

const auth = passport.authenticate('bearer', { session: false })

const allowedKeys = ['list-order', 'settings-general', 'settings-language']
meta.get('/', auth, async (req, res) => {
  res.send({ keys: allowedKeys })
})
meta.get('/:keyid', auth, async (req, res) => {
  if (!allowedKeys.includes(req.params.keyid)) {
    return res.status(400).send({ message: 'key not allowed' })
  }
  const data = await Meta.findOne({
    where: {
      key: req.params.keyid
    },
    include: {
      model: User,
      attributes: [],
      where: {
        id: req.user
      }
    }
  })
  if (data === null) {
    res.status(404).send({ message: 'key has no data' })
  } else {
    res.send(data.value)
  }
})
meta.post('/:keyid', auth, async (req, res) => {
  if (allowedKeys.includes(req.params.keyid)) {
    // TODO: max size
    const response = await Meta.create({
      key: req.params.keyid,
      value: req.body,
      userId: req.user
    })
    res.send(response)
  } else {
    res.status(400).send({ message: 'Key Name is Invalid' })
  }
})

module.exports = meta
