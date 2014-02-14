Promise = require('bluebird')
db = require '../controllers/database'

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


class UserPref

  @Pref: Pref

  constructor: (@userId) ->

  create: (pref={}) ->
    pref.userId = @userId
    Pref.create(pref)

  get: (id) ->
    new Pref(id)

  owns: (id) ->
    if id isnt @userId
      return Promise.reject new Error('err_does_not_own')
    db.pref.search('*', { @userId }).return(true)

  all: ->
    @get(@userId).read()

  destroy: ->
    db.pref.destroy({ @userId })


module.exports = UserPref
