const router = require('express').Router()
const passport = require('passport')
const jwt = require('jsonwebtoken')
const BearerStrategy = require('passport-bearer-strategy')
const config = require('../config/config.js')
const bodyParser = require('body-parser')

const authentication = require('./controllers/authentication')
const users = require('./controllers/users')
const lists = require('./controllers/lists')
const archive = require('./controllers/archivedtasks')

passport.use(new BearerStrategy(
  function(token, done) {
    jwt.verify(token, config.jwtsecret, function(err, decoded) {
      // errors aren't json, but whatever?
      // you should be checking http status anyway
      if (err) {
        return done(null, false)
      }
      return done(null, decoded.user)
    })
  }
))

router.use(function(req, res, next) {
  res.header('Access-Control-Allow-Origin', '*')
  res.header('Access-Control-Allow-Methods', 'GET, PUT, POST, PATCH, DELETE')
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization')
  next()
})
router.use(bodyParser.json()) // can parse post requests
router.use('/auth', authentication)
router.use('/users', users)
router.use('/lists', lists)
router.use('/archive', archive)

module.exports = router