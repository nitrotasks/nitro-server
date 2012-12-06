express = require('express')
http    = require('http')

port = process.env.PORT || 5000

app = express()
server = app.listen(port)
io = require('socket.io').listen(server)

app.configure ->
  app.use express.static(__dirname + '/public')

# Configure for Heroku
io.configure ->
  io.set "log level", 1
  io.set "transports", ["xhr-polling"]
  io.set "polling duration", 10

# Store user data
storage =
  "username":
    data:
      Settings: [{"sort":true,"id":"c-0"}]
      List: [{"name":"Hfiiywrst","id":"c-0"}]
      Task: [{"name":"# low That is awesome","completed":false,"priority":1,"list":"inbox","id":"c-0"},{"name":"#medium","completed":false,"priority":2,"list":"c-0","id":"c-2"},{"name":"#high","completed":false,"priority":3,"list":"c-0","id":"c-4"},{"name":"Just a test","completed":false,"priority":1,"list":"inbox","id":"c-3"}]

# User connects
io.sockets.on 'connection', (socket) ->

  user = null

  socket.on 'fetch', (data, fn) ->
    [uname, model] = data
    if uname of storage
      user = storage[uname]
      fn user.data[model]

  # Create a new model
  socket.on 'create', (data) ->
    [model, item] = data
    console.log model
    switch model
      when "Task"
        user.data.Task.push(item)
      when "list"
        user.data.List.push(item)
    console.log item.name
    socket.broadcast.emit 'create', [model, item]

  # Update existing model
  socket.on 'update', (data) ->
    [model, item] = data
    switch model
      when "Task"
        for task, index in user.data.Task
          if task.id is item.id then break
        user.data.Task[index] = item
    console.log "Updated: #{ item.name }"
    socket.broadcast.emit 'update', [model, item]

  # Delete existing model
  socket.on 'destroy', (data) ->
    [model, id] = data
    switch model
      when "Task"
        for task, index in user.data.Task
          if task.id is id then break
        user.data.Task.splice(index, 1)
    console.log "Item #{ id } has been destroyed"
    socket.broadcast.emit 'destroy', [model, id]
