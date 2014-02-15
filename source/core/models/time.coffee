Promise = require('bluebird')
db      = require('../controllers/database')

class Time

  constructor: (tableName) ->
    db.connected.then =>
      @table = db[tableName]

  create: (id, time) ->
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
    @read(id, @table.columns).then (times) ->
      for attr, val of times when val >= time
        throw new Error 'err_old_time'
      return true

  checkMultiple: (id, times) ->
    @read(id, Object.keys(times)).then (current) ->
      for attr, time of times when current[attr] >= time
        delete times[attr]
      return times

  updateMultiple: (id, changes, times) ->
    for key of changes when not times[key]?
      times[key] = utils.now()
    @checkMultiple(id, times)
    .then (times) =>
      for key of changes when not times[key]
        delete changes[key]
      @update(id, times)
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
