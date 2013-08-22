###
           ___  __   __      __            __
    |\ | |  |  |__) /  \    /__` \ / |\ | /  `
    | \| |  |  |  \ \__/    .__/  |  | \| \__,

    ------------------------------------------

    This is the sync code. It's messy.

###


Q       = require 'q'
Auth    = require './auth'
User    = require './user'
Log     = require('./log')('Sync', 'cyan')
LogEvent = require('./log')('Sync Event', 'yellow')

# Constants
SUPPORTED_CLASSES = ['List', 'Task', 'Setting']

# Expose io to all functions in this file
io = null

# Start server
init = ( sync_server ) ->

  # Start SocketIO
  io = require('socket.io').listen(sync_server)

  # Socket.IO settings
  io.configure ->

    # Hide irrelevant messages
    io.set 'log level', 1

    # Prevent unauthorised access to server
    io.set 'authorization', (handshakeData, fn) ->
      uid = handshakeData.query.uid
      token = handshakeData.query.token
      if DebugMode
        Log "Received uid #{ uid } and token #{ token }"
      if uid? and token?
        User.checkLoginToken(uid, token)
          .then (exists) ->
            handshakeData.uid = uid
            fn(null, exists)
          .fail ->
            Log 'User could not login'
      else
        fn(null, no)
      return true

  # Fired when user connects to server
  io.sockets.on 'connection', (socket) ->
    # Create a new Sync instance
    new Sync(socket)
    return true

  return true


# Return the default task object
# I don't think we even use this anymore?
Default = (name) ->

  data =
    Task:
      completed: false
      date: ''
      list: 'inbox'
      name: 'New Task'
      notes: ''
      priority: 1
    List:
      name: 'New List'
      tasks: []

  clone = (obj) ->
    newObj = {}
    for key, value of obj
      newObj[key] = value
    return newObj

  if data[name]
    return clone data[name]


# Does all the useful stuff
class Sync

  # Expose init function
  @init: init

  # Socket.IO events
  events:
    'disconnect' : 'logout'
    'fetch'      : 'fetch'
    'sync'       : 'sync'
    'create'     : 'create'
    'update'     : 'update'
    'destroy'    : 'destroy'
    'info'       : 'info'
    'emailList'  : 'emailList'

  constructor: (@socket, uid=@socket.handshake.uid, callback) ->
    Log 'A user has connected to the server'
    # Bind socket.io events
    for event, fn of @events
      @on event, @[fn]
    # Start login process
    @login(uid).then (user) ->
      if callback? then callback(user)


  # ------------------
  # Storage Functions
  # ------------------

  # Return model
  findModel: (className, id) =>
    @user.data(className)[id] ?= {}
    return @user.data(className)[id]

  hasModel: (className, id) =>
    return @user.data(className)?[id]?

  # Update attributes
  setModelAttributes: (className, id, attributes) =>
    model = @findModel className, id
    for key, value of attributes
      model[key] = value
    @user.save(className)
    return model

  # Replace model
  setModel: (className, id, attributes) =>
    @user.data(className)[id] = attributes
    @user.save(className)
    return attributes

  # Convert data object into spine array
  exportModel: (className) =>
    models = []
    data = @user.data(className)
    return [] unless data
    # Return all live items
    for id, model of data
      if not model.deleted
        models.push model
    return models


  # -------------------
  # Timestamp functions
  # -------------------

  # Used to shorten timestamps
  # Set to the 1st of Jan, 2013
  baseTime: 1356951600000

  # Return timestamp for an item or attribute
  getTime: (className, id, attr) =>
    time = @findModel('Time', className)?[id]?[attr]
    if time then time += @baseTime
    return time

  # Remove all timestamps for an object
  clearTime: (className, id) =>
    delete @findModel('Time', className)[id]
    return id

  # Set timestamp for an attribute
  setTime: (className, id, attr, time) =>

    # If attr is an object, loop through it
    if typeof attr is 'object'
      for key, time of attr
        @setTime className, id, key, time
      return

    # Compress timestamp to save space
    time -= @baseTime

    # Makes sure the entry exists
    # Todo: Make a function that will make this work
    @findModel('Time', className)[id] ?= {}

    # Update all existing values
    if attr is 'all'
      for attr of @findModel(className, id)
        continue if attr is 'id' # Ignore ID
        # Can't use @setModelAttributes because it's three layers deep
        @user.data('Time')[className][id][attr] = time
    else
      @user.data('Time')[className][id][attr] = time
    @user.save('Time')

    return

  # Check if the variable `time` is greater than any times stored in the DB
  checkTime: (className, id, time) =>

    return unless @findModel('Time', className)?[id]?

    pass = yes

    for attr of @findModel('Time', className)[id]
      val = @getTime(className, id, attr)
      if val > time then pass = no

    return pass




  # -----------------
  # Socket.IO Comands
  # -----------------

  # Emit event (goes to everyone)
  emit: (event, data) =>
    LogEvent "Emitting '#{ event }'"
    @socket.emit(event, data)

  # Broadcast event (goes to everyone except @user)
  broadcast: (event, data) =>
    LogEvent "Broadcasting '#{ event }'"
    @socket.broadcast.to(@user.id).emit(event, data)

  # Bind event to function
  on: (event, fn) =>
    @socket.on event, (args...) =>
      LogEvent "Received '#{ event }'"

      if @userIsLoaded
        fn(args...)

      else
        Log 'User is not loaded yet. Will run on load.'
        @runOnUserLoad.push ->
          fn(args...)


  # --------------
  # General Events
  # --------------

  login: (uid) =>
    deferred = Q.defer()
    Log "User #{ uid } is logging in"
    User.get(uid)
      .then (@user) =>
        # Move user to their own room
        @socket.join(@user.id)
        Log "#{ @user.name } has logged in"
        # Load user
        @userIsLoaded = true
        fn() for fn in @runOnUserLoad
        @runOnUserLoad = []
        deferred.resolve user
      .fail (error) ->
        deferred.reject(error)
    return deferred.promise

  logout: =>
    Log "#{ @user.name } has logged out"

    # If the user is only logged in from one client then remove them from memory
    if io.sockets.clients(@user.id).length is 1
      Log '... and has been removed from memory'
      User.release @user.id

  # Return all models in database
  fetch: (className, fn) =>
    return unless fn
    fn @exportModel(className)

  # Sometimes events can be sent to the server before we have loaded the user
  # data from the server. So we store those events and then fire them when the
  # user data # has loaded.

  userIsLoaded: false
  runOnUserLoad: []


  # ---------------
  # Realtime Events
  # ---------------


  #####################################
  #    __   __   ___      ___  ___    #
  #   /  ` |__) |__   /\   |  |__     #
  #   \__, |  \ |___ /~~\  |  |___    #
  #                                   #
  #####################################


  # Create a new model
  create: (data, fn) =>
    [className, model] = data
    return unless className in SUPPORTED_CLASSES

    # Generate new id
    if className is 'Setting'
      id = 1
      model = @settingsValidate(model)

    else if className is 'List' and model.id is 'inbox'
      id = model.id
      if @hasModel('List', 'inbox') then return
    
    else
      id = 's-' + @user.index(className)
      @user.incrIndex className
      model.id = id

    # Add task to list
    if className is 'Task'
      listId = model.list
      @taskAdd id, listId
    else if className is 'List'
      model.tasks = []

    # Add item to server
    @setModel(className, id, model)
    # Set timestamp
    timestamp = data[2] or Date.now()
    @setTime className, id, 'all', timestamp
    Log "Created #{ className }: #{ model.name }"
    # Broadcast event to connected clients
    @broadcast 'create', [className, model]
    # Return new ID
    if fn? then fn(id)



  ####################################
  #         __   __       ___  ___   #
  #   |  | |__) |  \  /\   |  |__    #
  #   \__/ |    |__/ /~~\  |  |___   #
  #                                  #
  ####################################

  # Update existing model
  update: (data) =>
    [className, changes] = data
    return unless className in SUPPORTED_CLASSES

    if className is 'Setting'
      id = 1
      changes = @settingsValidate(changes)
    else
      id = changes.id

    # Check model exists on server
    if not @hasModel(className, id)
      Log "#{className} doesn't exist on server"
      return
      # model = Default className
      # for k, v of changes
      #   model[k] = v
      # changes = model

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
        continue if k is 'id'
        timestamps[k] = now

    @setTime className, id, timestamps

    # Update list
    if className is 'Task' and changes.list?
      oldTask = @findModel className, id
      if oldTask.list isnt changes.list
        @taskMove id, oldTask.list, changes.list

    # Save to server
    model = @setModelAttributes className, id, changes
    Log "Updated #{ className }: #{ model.name }"

    # Broadcast event to connected clients
    @broadcast 'update', [className, model]



  ########################################
  #    __   ___  __  ___  __   __        #
  #   |  \ |__  /__`  |  |__) /  \ \ /   #
  #   |__/ |___ .__/  |  |  \ \__/  |    #
  #                                      #
  ########################################

  # Delete existing model
  destroy: ([className, id], timestamp=Date.now()) =>
    return unless className in SUPPORTED_CLASSES
    model = @findModel className, id

    # Check that the model hasn't been updated after this event
    return unless @checkTime className, id, timestamp

    # Destroy all tasks within that list
    if className is 'List'
      for taskId in model.tasks
        Log "Destroying Task #{ taskId }"
        # TODO: Prevent server from broadcasting these changes
        #       And make the client delete the tasks
        @destroy ['Task', taskId]

    # Remove from list
    else if className is 'Task'
      @taskRemove id, model.list

    # Replace task with deleted template
    @setModel className, id,
      id: id
      deleted: yes

    # Set timestamp
    @setTime className, id, 'deleted', timestamp
    Log "Destroyed #{ className } #{ id }"
    @broadcast 'destroy', [className, id]


  # --------------------
  # Offline Sync Merging
  # --------------------

  # Sync
  sync: (queue, fn) =>
    Log 'Running sync'

    # Map client IDs to server IDs -- for lists only
    client = {}

    for item, i in queue

      # TODO: Can't remember what this does.
      # I think it stops it from infinite looping.
      break if i >= 100

      [type, [className, model], timestamp] = item

      ## Handles client list IDs ##

      # Example: You create a task in list 'c-10'
      # The list ID gets changed to 's-5' on the server
      # This code matches that list back to the task

      if type in ['create', 'update'] and
      className is 'Task' and model.list.slice(0,2) is 'c-'

        # The list hasn't been assigned a server ID yet
        if client[model.list] is undefined

          # We have already checked this task
          if model._missing
            Log 'We have a missing task!'
            i++
            continue

          else
            Log "Moving Task #{model.id} in list #{model.list} to back of queue"
            model._missing = yes
            queue[queue.length] = queue[i]
            queue[i] = []
            i++
            continue

        else
          Log "Found List ID #{ model.list } has changed to #{ client[model.list] }"
          model.list = client[model.list]
          delete model._missing

      switch type
        when 'create'
          oldId = model.id
          @create [className, model, timestamp], (newId) ->
            if className is 'List'
              Log "Changing List #{ oldId } to #{ newId }"
              client[oldId] = newId

        when 'update'
          @update [className, model, timestamp]

        when 'destroy'
          @destroy [className, model, timestamp]

      i++

    fn [@exportModel('Task'), @exportModel('List')] if fn

  # Make sure data is in the right format
  parse: (event, data) ->
    return data


  # ----------
  # Task Order
  # ----------

  # Add a task to a list
  taskAdd: (taskId, listId) ->
    tasks = @findModel('List', listId).tasks
    return false unless tasks
    if tasks.indexOf(taskId) < 0
      tasks.push taskId
      @setModelAttributes 'List', listId, tasks:tasks

  # Remove a task from a list
  taskRemove: (taskId, listId) ->
    tasks = @findModel('List', listId).tasks
    return false unless tasks
    index = tasks.indexOf taskId
    if index > -1
      tasks.splice index, 1
      @setModelAttributes 'List', listId, tasks:tasks

  # Move a task from list to another
  taskMove: (taskId, oldListId, newListId) ->
    @taskAdd taskId, newListId
    @taskRemove taskId, oldListId

  # Replace a task ID
  taskUpdateId: (oldId, newId, listId) ->
    tasks = @findModel('List', listId).tasks
    index = tasks.indexOf oldId
    if index > -1
      tasks.spice index, 1, newId
      @setModelAttributes 'List', listId, tasks:tasks


  # -------------------
  # Settings Validation
  # -------------------

  settingsValidate: (settings) ->
    allowed = ['sort', 'weekStart', 'dateFormat', 'completedDuration',
               'confirmDelete', 'night', 'language', 'notifications',
               'notifyEmail', 'notifyTime', 'notifyRegular']
    out = {}
    for property in allowed
      if settings.hasOwnProperty(property)
        out[property] = settings[property]
    return out


  # --------------------
  # Miscellaneous events
  # --------------------

  ###*
   * Send the user info
  ###
  info: (id, sendback) =>
    sendback
      name: @user.name
      email: @user.email
      pro: @user.pro

  ###*
   * Send a users list to an email address
   * @param {integer} uid: a user ID
   * @param {string} listId: a list ID
   * @param {string} email: an email address
   * @return {boolean} false: if error
  ###
  emailList: (data) ->
    return false unless Array.isArray(data)
    [uid, listId, email] = data
    require('./todo.html')(uid, listId)
      .then ([data, user]) ->
        listName = user.data('List')[listId]?.name
        options =
          to: email
          replyTo: user.email
          from: "#{ user.name } <hello@nitrotasks.com>"
          subject: "I've sent you my #{ listName } list"
          html: data
          generateTextFromHTML: true
        console.log options
        require('./mail').send(options)
      .fail (error) ->
        console.warn error

module.exports = Sync
