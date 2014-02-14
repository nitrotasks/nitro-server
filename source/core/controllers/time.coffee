db = require '../controllers/query'

TIME = 'time'
PREFIX = 'time_'

time =

  # Return current time
  now: ->
    Math.floor Date.now() / 1000

  # Return timestamp for an item or attribute
  read: (classname, id, column) ->
    db[PREFIX + classname].read(id, column)


  # Remove all timestamps for an object
  destroy: (classname, id) ->
    db[PREFIX + classname].destroy(id)


  # Update timestamps for an attribute
  update: (classname, id, attr, time) ->

    # If attr is an object, loop through it
    if typeof attr is 'object'
      obj = attr
    else
      obj = {}
      obj[attr] = time

    db[PREFIX + classname].update id, obj


  ###
   * Create Time
   *
   * Set multiple timestamps.
   * Will add id property to attrs object.
   *
   * - classname (string)
   * - id (int)
   * - attrs (object)
  ###

  create: (classname, id, attrs) ->

    attrs.id = id
    db[PREFIX + classname].create(attrs)


  createTask: (id, time) ->
    @create 'task', id,
      listId: time
      name: time
      notes: time
      priority: time
      date: time
      completed: time

  createList: (id, time) ->
    @create 'list', id,
      name: time
      tasks: time

  createPref: (id, time) ->
    @create 'pref', id,
      sort: time
      night: time
      language: time
      weekStart: time
      dateFormat: time
      confirmDelete: time
      moveCompleted: time

  # Check if the variable `time` is greater than any times stored in the DB
  checkSingle: (classname, id, time) ->

    @read(classname, id).then (times) ->

      pass = yes

      for attr, val of times
        if val > time then pass = no

      return pass

  checkMultiple: (classname, id, times) ->

    keys = Object.keys times
    old = []

    @read(classname, id, keys).then (timestamps) ->

      for attr, time of times
        current = timestamps[attr]

        if current > time
          old.push attr

      return old

  offset: (offset, time) ->

    if typeof time is 'object'
      for own key, value of time
        time[key] = value + offset
      return time

    return time + offset

module.exports = time