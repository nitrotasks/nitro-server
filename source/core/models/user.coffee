db   = require('../controllers/database')
Time = require('../models/time')
Prefs = require('../models/pref')
Lists = require('../models/list')
Tasks = require('../models/task')


class User

  ###
   * Create a new User instance
   *
   * - [attrs] (object) : optional attributes to load in
   * - [duration] (int) : how long to wait between writes
  ###

  constructor: (@id) ->
    @prefs = new Prefs(@id)
    @tasks = new Tasks(@id)
    @lists = new Lists(@id)

  setup: ->
    @pref.create()
    .then => Time.create('pref', @id, {})
    .return(this)

  read: (columns) ->
    db.user.read(@id, columns)

  update: (changes) ->
    db.user.update(@id, changes)

  destroy: ->
    db.user.destroy(@id, true)

module.exports = User