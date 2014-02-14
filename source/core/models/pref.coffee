Promise = require('bluebird')
db = require '../controllers/database'

class Pref

  constructor: (@userId) ->

  create: (pref) ->
    db.pref.create
      userId: @userId
      sort: pref.sort
      night: pref.night
      language: pref.language
      weekStart: pref.weekStart
      dateFormat: pref.dateFormat
      confirmDelete: pref.confirmDelete
      moveCompleted: pref.moveCompleted

  exists: ->
    db.pref.search('*', { @userId }).return(true)

  read: (columns) ->
    db.pref.read(@userId, columns)

  update: (changes) ->
    db.pref.update(@userId, changes)

  destroy: ->
    db.pref.destroy(@userId, true)

module.exports = Pref
