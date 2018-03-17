const url = require('url')
const Token = require('../models/token')

// maybe should store in redis or something?
const openConnections = {}

const instructSync = function(user, origin) {
  openConnections[user].forEach((socket) => {
    if (socket !== origin) {
      socket.send(JSON.stringify({
        command: 'sync-complete'
      }))
    }
  })
}

const connection = function(ws, req) {
  const location = url.parse(req.url, true)
  // should probs not be hardcoded???
  if ((location.pathname !== '/a/ws' && location.pathname !== '/ws') || typeof location.query.token === 'undefined') {
    return ws.terminate()
  }
  
  Token.findOne({
    where: {
      id: location.query.token
    }
  }).then(function(data) {
    const user = data.userId
    if (typeof openConnections[user] === 'undefined') {
      openConnections[user] = []
    }
    openConnections[user].push(ws)

    ws.on('message', function(message) {
      try {
        const msg = JSON.parse(message)
        if (msg.command === 'complete-sync') {
          instructSync(user, ws)
        }
      } catch(err) {
        return // could not parse json
      }      
    })

    // removes websocket from pool
    ws.on('close', function() {
      openConnections[user].splice(openConnections[user].indexOf(ws), 1)
    })
  }).catch(function() {
    return ws.terminate()
  })
}

module.exports = {
  connection: connection
}