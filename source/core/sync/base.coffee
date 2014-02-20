Promise = require('bluebird')
time    = require('../models/time')
Log     = require('log_')

ERR_INVALID_MODEL = 'err_invalid_model'

class Sync

  classname: null

  constructor: (@user) ->

    @model = @user[@classname]
    @time = time[@classname]
    @log = Log("Sync -> #{ @classname }", 'yellow')

  create: (data, timestamp) ->

    @model.create(data)
    .then (id) =>
      data.id = id
      @log '[create]', data
      @time.create(id, timestamp)
    .return(data)


  _update_validation: ->
    Promise.resolve()

  update: (id, data, timestamps) ->

    if Object.keys(data).length is 0
      Promise.reject new Error(ERR_INVALID_MODEL)

    model = null

    @model.get(id)
    .then (_model) =>
      model =_model
      @time.checkMultiple(id, data, timestamps)
    .then (_timestamps) =>
      timestamps = _timestamps
      @_update_validation(model, data, timestamps)
    .then =>
      @log '[update]', data
      Promise.all [
        model.update(data)
        @time.update(id, timestamps)
      ]
    .then ->
      model.read()

  destroy: (id, timestamp) ->

    @model.get(id)
    .then (model) =>
      @time.checkSingle(id, timestamp).return(model)
    .then (model) =>
      @log '[destroy]', id
      model.destroy()

module.exports = Sync
