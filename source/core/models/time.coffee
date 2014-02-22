Promise = require('bluebird')
db      = require('../controllers/database')

class Time

  constructor: (tableName) ->
    db.connected.then =>
      @table = db[tableName]

  create: (id, time=utils.now()) ->
    obj = { id }
    obj[key] = time for key in @table.columns
    @table.create(obj).return(id)

  read: (id, column) ->
    @table.read(id, column)

  update: (id, obj) ->
    @table.update(id, obj)

  destroy: (id) ->
    @table.destroy(id)

  checkSingle: (id, time) ->
    @read(id, @table.columns)
    .catch (ignore) -> {}
    .then (times) ->
      for attr, val of times when val > time
        throw new Error 'err_old_time'
      return true

  checkMultiple: (id, changes, times={}) ->
    # Make sure every change has a timestamp
    for key of changes when not times[key]?
      times[key] = utils.now()
    # Load the current timestamps from the db
    @read(id, Object.keys(times)).then (current) ->
      # Delete any old timestamps and data
      for attr, time of times when current[attr] > time
        delete changes[attr]
        delete times[attr]
      # Throw err if no properties are left
      if Object.keys(times).length is 0
        throw new Error 'err_old_time'
      return times

  updateMultiple: (id, changes, times={}) ->
    @checkMultiple(id, changes, times)
    .then => @update(id, times)
    .return(times)


# Utils
utils =

  # Return current time
  now: ->
    Math.floor Date.now() / 1000

  offset: (offset, time) ->

    if typeof time is 'object'
      for own key, value of time
        time[key] = value + offset
      return time

    return time + offset


module.exports =
  Time: Time
  list: new Time('time_list')
  task: new Time('time_task')
  pref: new Time('time_pref')
  now: utils.now
  offset: utils.offset
