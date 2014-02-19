Promise = require('bluebird')
jwt = Promise.promisifyAll require('jsonwebtoken')
exJwt = require('express-jwt')

AUDIENCE_SOCKET = 'ws'
AUDIENCE_SESSION = 'ht'

TIMEOUT_SOCKET = 5
TIMEOUT_SESSION = 60 * 5

secret = 'secret'

token =

  middleware: exJwt
    secret: secret
    audience: AUDIENCE_SESSION

  createSessionToken: (id) ->

    jwt.sign { id }, secret,
      expiresInMinutes: TIMEOUT_SESSION
      audience: AUDIENCE_SESSION

  verifySessionToken: (token) ->

    jwt.verifyAsync token, secret, { audience: AUDIENCE_SESSION }, fn

  createSocketToken: (id) ->

    jwt.sign { id }, secret,
      expiresInMinutes: TIMEOUT_SOCKET
      audience: AUDIENCE_SOCKET

  verifySocketToken: (token) ->

    jwt.verifyAsync token, secret, { audience: AUDIENCE_SOCKET }, fn


module.exports = token
