const url = require('url')
const config = require('../../config/config.js')
const Token = require('../models/token.js')
const middleware = require('../middleware.js')

// maybe should store in redis or something?
const openConnections = {}

const instructSync = function(user, origin) {
  openConnections[user]
    .filter(socket => socket !== origin)
    .forEach(socket => {
      socket.send(
        JSON.stringify({
          command: 'sync-complete'
        })
      )
    })
}

const getUser = (token, cb) => {
  if (config.jwtstrategy === 'auth0') {
    return new Promise((resolve, reject) => {
      middleware.strategy(token, (err, data) => {
        if (err) {
          return reject(err)
        }
        resolve(data)
      })
    })
  } else {
    return Token.findOne({
      where: {
        id: token
      }
    }).then(data => data.userId)
  }
}

const connection = function(ws, req) {
  const location = url.parse(req.url, true)
  // should probs not be hardcoded???
  if (
    (location.pathname !== '/a/ws' && location.pathname !== '/ws') ||
    location.query.token === undefined
  ) {
    return ws.terminate()
  }

  getUser(location.query.token)
    .then(user => {
      if (openConnections[user] === undefined) {
        openConnections[user] = []
      }
      openConnections[user].push(ws)

      ws.on('message', function(message) {
        try {
          const msg = JSON.parse(message)
          if (msg.command === 'complete-sync') {
            instructSync(user, ws)
          }
        } catch (err) {
          return // could not parse json
        }
      })

      // removes websocket from pool
      ws.on('close', function() {
        openConnections[user].splice(openConnections[user].indexOf(ws), 1)
      })
    })
    .catch(function() {
      return ws.terminate()
    })
}

module.exports = {
  connection: connection
}
