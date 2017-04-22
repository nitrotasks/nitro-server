const router = require('express').Router()
const pool = require('./db')

const authentication = require('./controllers/authentication')
const users = require('./controllers/users')

router.use('/auth', authentication)
router.use('/users', users)

module.exports = router