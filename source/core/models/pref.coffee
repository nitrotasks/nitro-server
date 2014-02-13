db = require '../controllers/database'


class UserPref

  constructor: (@userId) ->

  create: (pref={}) ->
    pref.userId = @userId
    Pref.create(pref)

  get: (id) ->
    new Pref(id)

  owns: (id) ->
    db.pref.exists(id: id, userId: @userId)

  all: ->
    @get(@userId).read('*')

  destroyAll: ->
    db.pref.destroy(userId: @userId)


class Pref

  @create: (pref) ->
    db.pref.create
      userId: pref.userId
      sort: pref.sort
      night: pref.night
      language: pref.language
      weekStart: pref.weekStart
      dateFormat: pref.dateFormat
      confirmDelete: pref.confirmDelete
      moveCompleted: pref.moveCompleted

  constructor: (@id) ->

  read: (columns) ->
    db.pref.read(@id, columns)

  update: (changes) ->
    db.pref.update(@id, changes)

  destroy: ->
    db.pref.destroy(@id, true)

module.exports = UserPref
