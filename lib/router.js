const router = require('express').Router()
const passport = require('passport')

const config = require('../config/config.js')
const authentication = require('./controllers/authentication')
const users = require('./controllers/users')
const lists = require('./controllers/lists')
const meta = require('./controllers/meta')
const archive = require('./controllers/archivedtasks')
const stats = require('./controllers/stats')

const middleware = require('./middleware')
middleware.setup(router)

const ping = (req, res) => res.send({ status: 'healthy' })
router.get('/', ping)
router.get('/ping', ping)
router.get('/healthcheck', ping)

// if you're using auth0, we remove the auth & users endpoints.
if (config.jwtstrategy === 'auth0') {
  router.get(
    '/auth/universal',
    passport.authenticate('bearer', { session: false }),
    (req, res) => {
      res.send({ user: req.user })
    }
  )
} else {
  router.use('/auth', authentication)
  router.use('/users', users)
}
router.use('/lists', lists)
router.use('/meta', meta)
router.use('/archive', archive)
router.use('/stats', stats)

module.exports = router
