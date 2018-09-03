const meta = require('express').Router()
const passport = require('passport')
const Meta = require('../models/meta')
const User = require('../models/user')

const auth = passport.authenticate('bearer', { session: false })

const allowedKeys = [
  'list-order',
  'settings-general',
  'settings-language',
  // these are not used, just for the integration tests
  'test-key',
  'test-key-2'
]
const getKey = (userId, keyId) => {
  return {
    where: {
      key: keyId
    },
    include: {
      model: User,
      attributes: [],
      where: {
        id: userId
      }
    }
  }
}
meta.get('/', auth, async (req, res) => {
  res.send({ keys: allowedKeys })
})
meta.get('/:keyid', auth, async (req, res) => {
  if (!allowedKeys.includes(req.params.keyid)) {
    return res.status(400).send({ message: 'key not allowed' })
  }
  const query = getKey(req.user, req.params.keyid)
  const data = await Meta.findOne(query)
  if (data === null) {
    res.status(404).send({ message: 'key has no data' })
  } else {
    res.send(data.value)
  }
})
meta.post('/:keyid', auth, async (req, res) => {
  if (allowedKeys.includes(req.params.keyid)) {
    // TODO: max size
    const query = getKey(req.user, req.params.keyid)
    const data = await Meta.findOne(query)
    let response = null
    if (data === null) {
      response = await Meta.create({
        key: req.params.keyid,
        value: req.body,
        userId: req.user
      })
    } else {
      response = await data.update({
        value: req.body
      })
    }
    res.send(response)
  } else {
    res.status(400).send({ message: 'Key Name is Invalid' })
  }
})

module.exports = meta
