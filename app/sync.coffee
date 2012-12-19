express = require "express"
http    = require "http"
Q       = require "q"
Auth    = require "./auth"
User    = require "./storage"

# Easy way to disable logging if needed
Log = (args...) =>
  # return
  args.unshift('(Sync)')
  console?.log?(args...)

# Start server
init = ->
  port = process.env.PORT || 5000

  app = express()
  server = app.listen(port)
  io = require('socket.io').listen(server)

  # Serve up static files in the public folder
  app.configure ->
    app.use express.static(__dirname + '/public')

  # Socket.IO settings
  io.configure ->
    # Hide messages
    io.set "log level", 1
    # Configure for Heroku
    # io.set "transports", ["xhr-polling"]
    # io.set "polling duration", 10

  # Fired when user connects to server
  io.sockets.on 'connection', (socket) ->
    # Create a new Sync instance
    new Sync(socket)

# Does all the useful stuff
class Sync

  # Starts socket.io server
  @init: init

  # Store user data
  user: no

  # Socket.IO events
  events:
    'disconnect': 'logout'
    'login': 'login'
    'fetch': 'fetch'
    'sync': 'sync'
    'create': 'create'
    'update': 'update'
    'destroy': 'destroy'

  constructor: (@socket) ->
    Log "-- A user has connected to the server --"
    # Bind socket.io events
    for event, fn of @events
      @on event, @[fn]


  # ------------------
  # Utility Functions
  # ------------------

  # Return model
  find: (className, id) =>
    data = @user.data(className)
    if !data
      data = @user.data(className, {})
    data?[id]

  # Update attributes
  set: (className, id, data) =>
    model = @find className, id
    for key, value of data
      model[key] = value
    @user.save(className)
    model

  # Replace model
  replace: (className, id, data) =>
    @user.data(className)[id] = data
    @user.save(className)

  # Convert data object into spine array
  getArray: (className) =>
    models = []
    data = @user.data(className)
    return [] unless data
    # Return all live items
    for id, model of data
      if not model.deleted
        models.push model
    models


  # -------------------
  # Timestamp functions
  # -------------------

  # Used to shorten timestamps
  # Set to the 1st of Jan, 2013
  baseTime: 1356951600000

  # Return timestamp for an item or attribute
  getTime: (className, id, attr) =>
    time = @user.data("Time")?[className]?[id]?[attr]
    if time then time += @baseTime
    time

  # Remove all timestamps for an object
  clearTime: (className, id) =>
    delete @user.data("Time")[className][id]
    @user.save("Time")

  # Set timestamp for an attribute
  setTime: (className, id, attr, time) =>

    # If attr is an object, loop through it
    if typeof attr is "object"
      for key, time of attr
        @setTime className, id, key, time
      return

    time -= @baseTime

    # Makes sure the entry exists
    if not @user.data("Time")
      @user.data("Time", {})
    if not (className of @user.data("Time"))
      @user.data("Time")[className] = {}
    if not (id of @user.data("Time")[className])
      @user.data("Time")[className][id] = {}

    # Update all existing values
    if attr is "all"
      for attr of @user.data(className)[id]
        continue if attr is "id" # Ignore ID
        @user.data("Time")[className][id][attr] = time
    else
      @user.data("Time")[className][id][attr] = time
    @user.save("Time")

  # Check if the variable `time` is greater than any times stored in the DB
  checkTime: (className, id, time) =>

    return unless @user.data("Time")?[className]?[id]?

    pass = yes

    for attr of @user.data("Time")[className][id]
      val = @getTime(className, id, attr)
      if val > time then pass = no

    return pass




  # -----------------
  # Socket.IO Comands
  # -----------------

  # Emit event
  emit: (name, data) =>
    @socket.broadcast.to(@user.name).emit(name, data)

  # Bind event to function
  on: (event, fn) =>
    @socket.on event, (args...) =>
      return unless @user or event is "login"
      fn(args...)


  # --------------
  # General Events
  # --------------

  # Temp function to handle usernames and rooms
  login: (username) =>

    deferred = Q.defer()

    Q.fcall( ->
      User.usernameExists username
    ).then( (exists) ->
      if exists
        User.getByName username
      else
        # Add user to database if they don't already exist
        User.add username, "email-#{Date.now()}", "password"
    ).then( (user) =>
      # Set user
      @user = user
      # Move user to their own room
      @socket.join(@user.username)
      Log "#{ @user.username } has logged in"
      deferred.resolve @user
    )

    return deferred.promise

  logout: =>
    Log "#{ @user.username } has logged out"
    Log "-- Releasing connection --"

  # Return all models in database
  fetch: (className, fn) =>
    # Create model in data
    if not @user.data(className) then @user.data(className, {})
    fn @getArray(className)


  # ---------------
  # Realtime Events
  # ---------------

  # Create a new model
  create: (data, fn) =>
    [className, model] = data
    return unless className in ["List", "Task"]
    # Generate new id
    id = "s-" + @user.index(className)
    @user.incrIndex className
    model.id = id
    # Add item to server
    group = @user.data(className)
    if not group
      group = @user.data(className, {})
    group[id] = model
    # Save to server
    @user.save(className)
    # Set timestamp
    timestamp = data[2] or Date.now()
    @setTime className, id, "all", timestamp
    Log "Created item: #{ model.name }"
    console.log id
    # Return new ID
    if fn? then fn(id)
    # Broadcast event to connected clients
    @emit 'create', [className, model]

  # Update existing model
  update: (data) =>
    [className, changes] = data
    return unless className in ["List", "Task"]
    id = changes.id
    # Set timestamp
    timestamps = data[2]
    if timestamps
      for attr, time of timestamps
        old = @getTime className, id, attr
        if old > time
          delete timestamps[attr]
          delete changes[attr]
    else
      timestamps = {}
      now = Date.now()
      for k of changes
        continue if k is "id"
        timestamps[k] = now
    @setTime className, id, timestamps
    # Save to server
    model = @set className, id, changes
    Log "Updated item: #{ model.name }"
    # Broadcast event to connected clients
    @emit 'update', [className, model]

  # Delete existing model
  destroy: (data) =>
    [className, id] = data
    return unless className in ["List", "Task"]
    # Check that the model hasn't been updated after this event
    timestamp = data[2] or Date.now()
    return unless @checkTime className, id, timestamp
    # Replace task with deleted template
    @replace className, id,
      id: id
      deleted: yes
    # Set timestamp
    @setTime className, id, "deleted", timestamp
    Log "Destroyed item #{ id }"
    @emit 'destroy', [className, id]


  # -----------
  # Sync Events
  # -----------

  # Sync
  sync: (queue, fn) =>
    Log "Running sync"
    for event in queue
      [type, [className, model], timestamp] = event
      switch type
        when "create"
          @create [className, model, timestamp]
        when "update"
          @update [className, model, timestamp]
        when "destroy"
          @destroy [className, model, timestamp]
    fn [@getArray("Task"), @getArray("List")] if fn

module?.exports = Sync
