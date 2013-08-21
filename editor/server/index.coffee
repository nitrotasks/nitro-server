# Dependencies
global.DebugMode = true
Log = require('../../app/log')('Editor', 'white')
database = require('../../app/database')
express = require('express')

# Config
PORT = 8001

# Create a new express web server
app = express()

# Connect to database
database.connect()

# Serve up static files in the client folder
app.configure ->
  app.use express.static(__dirname + '/../client')
  app.use express.bodyParser()

# Fetch data from database
app.get /^\/read\/(\d*)/, (req, res) ->
  [uid] = req.params
  database.user.read(uid).then (user) ->
    res.send user

# Save changes to database
app.post /^\/update\/(\d*)/, (req, res) ->
  [uid] = req.params
  user = JSON.parse req.body.user
  database.user.write(user)
  res.end()

app.listen(PORT)
Log "Started on port #{PORT}"

