express = require "express"
Auth    = require "./app/auth"

port = process.env.PORT || 5000

app = express()

# Serve up static files in the public folder
app.configure ->
  app.use express.static(__dirname + '/public')
  app.use express.bodyParser()

  # Allow CORS
  app.all "/*", (req, res, next) ->
    res.header "Access-Control-Allow-Origin", "*"
    res.header "Access-Control-Allow-Headers", "X-Requested-With"
    next()

# GET and POST requests
api =
  "v0":
    "auth":
      "post_register": (req, res) ->
        user =
          name: req.body.name
          email: req.body.email
          password: req.body.password
        Auth.register(user.name, user.email, user.password).then( (data) ->
          res.send data
        ).fail( (err) ->
          res.status(400).send err
        )
      "post_login": (req, res) ->
        user =
          email: req.body.email
          password: req.body.password
        Auth.login(user.email, user.password).then( (data) ->
          res.send data
        ).fail( (err) ->
          res.status(401).send err
        )

# Bind requests to Express App
bind = (obj, prefix, app) ->
  for key, value of obj
    if (typeof value is "object") and not Array.isArray value
      bind value, "#{prefix}/#{key}", app
    else
      if key.slice(0,4) is "get_"
        app.get "/#{prefix}/#{key.slice(4)}", value
      else if key.slice(0,5) is "post_"
        app.post "/#{prefix}/#{key.slice(5)}", value
bind api, "api", app

# Start Server
server = app.listen(port)

# Start sync
Sync = require "./app/sync"
Sync.init server

module.exports = app
