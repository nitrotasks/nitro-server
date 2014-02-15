db = require '../controllers/database'

TIME = 'time'
PREFIX = 'time_'

time =

  # Return current time
  now: ->
    Math.floor Date.now() / 1000

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



  ###
   * (private) Model Update Timestamps
   *
   * Handle timestamps for an update event
   *
   * - classname (string)
   * - id (string)
   * - changes (object)
   * - timestamps (object)
   * > timestamps
  ###

  model_update_timestamps: (classname, id, changes, timestamps) ->

    if timestamps

      keys = hasSameKeys(changes, timestamps)

      if keys is false
        return Promise.reject ERR_INVALID_MODEL

      time.checkMultiple(classname, id, timestamps)

      .then (oldKeys) ->

        for key in oldKeys
          delete timestamps[key]
          delete changes[key]

        if oldKeys.length is keys.length
          throw ERR_OLD_EVENT

        return timestamps


    else
      timestamps = {}
      now = time.now()
      for key of changes
        timestamps[key] = now

      Promise.resolve timestamps


hasSameKeys = (a, b) ->

  aKeys = Object.keys(a)
  bKeys = Object.keys(b)

  if aKeys.length is bKeys.length
    if aKeys.every( (key) -> b.hasOwnProperty(key) )
      return aKeys

  return false


module.exports = time
