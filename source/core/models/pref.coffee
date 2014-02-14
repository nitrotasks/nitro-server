Promise = require('bluebird')
db = require '../controllers/database'

class Pref

  constructor: (@id) ->

  create: (pref) ->
    db.pref.create
      userId: @id
      sort: pref.sort
      night: pref.night
      language: pref.language
      weekStart: pref.weekStart
      dateFormat: pref.dateFormat
      confirmDelete: pref.confirmDelete
      moveCompleted: pref.moveCompleted

  exists: ->
    db.pref.search('*', { @id }).return(true)

  read: (columns) ->
    db.pref.read(@id, columns)

  update: (changes) ->
    db.pref.update(@id, changes)

  destroy: ->
    db.pref.destroy(@id, true)

module.exports = Pref
