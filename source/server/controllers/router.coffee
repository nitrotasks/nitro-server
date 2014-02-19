express = require('express')
cors    = require('cors')
log     = require('log_')('Router', 'magenta')
token   = require('./token')

init = (config) ->

  app = express()

  app.configure ->

    # Log
    app.use express.logger()

    # Parse POST requests
    app.use express.json()
    app.use express.urlencoded()

    # Allow Cross-Origin Resource Sharing
    app.use cors({ origin: config.client })

    # Protect api
    app.use '/api/', token.middleware


# -----------------------------------------------------------------------------
# Routes
# -----------------------------------------------------------------------------

  routes = [
    'api'
    'socket'
    'refresh_token'
    'login'
    'register'
    'reset'
    'root'
    '404'
    # 'oauth'
    # 'payment'
  ]

  # Bind an array of routes to the server
  for route in routes
    route = require '../routes/' + route
    for path in route
      if path.type is 'get'
        log 'GET ', path.url
      else
        log 'POST', path.url
      app[path.type] path.url, path.handler

  return app

module.exports =
  init: init
