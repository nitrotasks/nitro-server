const router = require('express').Router()
const passport = require('passport')
const jwt = require('jsonwebtoken')
const BearerStrategy = require('passport-bearer-strategy')
const config = require('../config')
const bodyParser = require('body-parser')

const authentication = require('./controllers/authentication')
const users = require('./controllers/users')

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

router.use(bodyParser.json()) // can parse post requests
router.use('/auth', authentication)
router.use('/users', users)

module.exports = router