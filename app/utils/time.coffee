
# Since timestamps are quite long, and are based on the 1st of January 1970,
# it is possible to save space in the database by subtracting a fixed date from 
# the timestamp.
# Set to the 1st of January, 2014
BASE = 1388487600000
TIME = 'time'

class Time

  constructor: (@user) ->

  # Return timestamp for an item or attribute
  get: (className, id, attr) =>
    time = @user.findModel(TIME, className)?[id]?[attr]
    if time then time += BASE
    return time

  # Remove all timestamps for an object
  clear: (className, id) =>
    delete @user.findModel(TIME, className)[id]
    return id

  # Set timestamp for an attribute
  set: (className, id, attr, time) =>

    # If attr is an object, loop through it
    if typeof attr is 'object'
      for key, time of attr
        @set className, id, key, time
      return

    # Compress timestamp to save space
    time -= BASE

    # Makes sure the entry exists
    # Todo: Make a function that will make this work
    @user.findModel(TIME, className)[id] ?= {}

    # Update all existing values
    if attr is '*'
      for attr of @user.findModel(className, id)
        continue if attr is 'id' # Ignore ID
        # Can't use @setModelAttributes because it's three layers deep
        @user.data(TIME)[className][id][attr] = time
    else
      @user.data(TIME)[className][id][attr] = time
    @user.save(TIME)

    return

  # Check if the variable `time` is greater than any times stored in the DB
  check: (className, id, time) =>

    return unless @user.findModel(TIME, className)?[id]?

    pass = yes

    for attr of @user.findModel(TIME, className)[id]
      val = @get(className, id, attr)
      if val > time then pass = no

    return pass

module.exports = Time
