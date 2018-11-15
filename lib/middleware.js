const passport = require('passport')
const bodyParser = require('body-parser')
const BearerStrategy = require('passport-bearer-strategy')
const jwt = require('jsonwebtoken')

const config = require('../config/config.js')
const User = require('./models/user')

let strategy = null
if (config.jwtstrategy === 'auth0') {
  const jwks = require('jwks-rsa')
  const jwksClient = jwks({
    cache: true,
    rateLimit: true,
    jwksRequestsPerMinute: 5,
    jwksUri: config.jwksuri
  })
  const getKey = (header, callback) => {
    jwksClient.getSigningKey(header.kid, function(err, key) {
      if (err) {
        return callback(err)
      }
      const signingKey = key.publicKey || key.rsaPublicKey
      callback(null, signingKey)
    })
  }
  const userCache = new Map()
  const mapUserToGuid = async (username, createAccount = true) => {
    let id = userCache.get(username)
    if (id !== undefined) {
      return id
    }
    const user = await User.findOne({
      where: {
        username: username
      },
      attributes: ['id', 'password']
    })
    if (user === null && createAccount === false) {
      throw new Error('No account exists.')
    } else if (user === null) {
      const newUser = await User.create({
        username: username,
        loginType: username.split('|')[0]
      })
      id = newUser.id
    } else {
      id = user.id
    }
    userCache.set(username, id)
    return id
  }
  strategy = (token, done) => {
    const header = jwt.decode(token, { algorithms: 'RS256', complete: true })
      .header
    getKey(header, function(err, secret) {
      if (err) {
        return done(null, false)
      }
      try {
        // TODO: verify scopes
        const decoded = jwt.verify(token, secret, {
          algorithms: 'RS256',
          audience: config.jwtaudience,
          issuer: config.jwtissuer
        })
        mapUserToGuid(decoded.sub)
          .then(user => {
            done(null, user)
          })
          .catch(err => {
            done(null, false)
          })
      } catch (err) {
        done(null, false)
      }
    })
  }
} else {
  strategy = (token, done) => {
    try {
      const decoded = jwt.verify(token, config.jwtsecret)
      return done(null, decoded.user)
    } catch (err) {
      return done(null, false)
    }
  }
}
const setup = router => {
  passport.use(new BearerStrategy(strategy))

  router.use(function(req, res, next) {
    res.header('Access-Control-Allow-Origin', '*')
    res.header('Access-Control-Allow-Methods', 'GET, PUT, POST, PATCH, DELETE')
    res.header(
      'Access-Control-Allow-Headers',
      'Origin, X-Requested-With, Content-Type, Accept, Authorization'
    )
    next()
  })
  router.use(bodyParser.json()) // can parse post requests
}

module.exports = {
  strategy: strategy,
  setup: setup
}
