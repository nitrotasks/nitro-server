Q = require 'kew'

class Table

  table: null

  ERR_NO_ROW: 'err_no_row'

  constructor: (@query) ->

  setup: ->

  exec: (fn) ->

    deferred = Q.defer()
    fn.exec deferred.makeNodeResolver()
    return deferred.promise


  createTable: (fn) ->

    promise = @exec @query.schema.hasTable(@table)

    promise.then (exists) =>
      return if exists
      @exec @query.schema.createTable(@table, fn)

  ###
   * Create
   *
   * Create a new row
   *
   * - data (object) : the data data
   * > id (number) : the new id of the user
  ###

  create: (data) ->

    promise = @exec @query(@table).insert(data)

    promise.then (id) ->
      return id[0]


  ###
   * Read
   *
   * Retrieve data from an existing row.
   *
   * - id (number) : id of the row
   * - [columns] (array|string) : columns to retrieve
   * > row (object) : the row data
   * ! err_no_row : row cannot be found
  ###

  read: (id, columns) ->

    promise = @exec @query(@table).column(columns).where('id', id).select()

    promise.then (rows) =>
      unless rows.length then throw @ERR_NO_ROW
      return rows[0]


  ###
   * Update
   *
   * Update attributes in an existing row.
   *
   * - id (number) : the id of the row
   * - data (object) : attributes to set in the row
   * > id (number)
   * ! err_no_row : row cannot be found
  ###

  update: (id, data) ->

    promise = @exec @query(@table).where('id', id).update(data)

    promise.then (rows) =>
      unless rows then throw @ERR_NO_ROW
      return rows


  ###
   * Destroy
   *
   * Destroy an existing row.
   *
   * - id (number) : id of row to destroy
   * > true
   * ! err_no_row : row cannot be found
  ###

  destroy: (id) ->

    promise = @exec @query(@table).where('id', id).del()

    promise.then (rows) =>
      unless rows then throw @ERR_NO_ROW
      return true


module.exports = Table
