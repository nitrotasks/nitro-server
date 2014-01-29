Q = require 'kew'

class Table

  ###
   * Table (string)
   *
   * This should store the table name
  ###

  table: null

  ###
   * Constants
  ###

  ERR_NO_ROW: 'err_no_row'


  ###
   * Table Constructor
   *
   * - query (function) : the Knex builder
  ###

  constructor: (@query) ->


  ###
   * Setup
   *
   * This will be called after initialization to setup the table.
   * It should return a promise so that we can tell when all the tables
   * are ready.
   *
   * > Promise
  ###

  setup: ->


  ###
   * Wrap
   *
   * Converts the Knex builder into a Kew promise
   *
   * - fn (Knex) : The knex builder
  ###

  wrap: (fn) ->

    deferred = Q.defer()
    fn.exec deferred.makeNodeResolver()
    return deferred.promise


  ###
   * (private) Create Table
   *
   * Creates a table if it does not already exist
   *
   * - fn (function) : will be passed to knex.schema.createTable
  ###

  _createTable: (fn) ->

    promise = @query.schema.hasTable(@table)

    @wrap(promise).then (exists) =>
      return if exists
      @wrap @query.schema.createTable(@table, fn)

  _dropTable: ->

    @wrap @query.schema.dropTable(@table)

  _parseToken: (token) ->
    match = token.match(/^(\d+)_(\w+)$/)
    if match is null then return null
    return [match[1], match[2]]


  _search: (columns, data) ->

    promise = @query(@table).select().column(columns).where(data)
    @wrap(promise).then (rows) =>
      unless rows.length then throw @ERR_NO_ROW
      return rows


  _update: (data, where) ->

    promise = @query(@table).update(data).where(where)
    @wrap(promise).then (rows) =>
      unless rows then throw @ERR_NO_ROW
      return rows


  _delete: (data) ->

    promise = @query(@table).del().where(data)
    @wrap(promise).then (rows) =>
      return rows > 0


  ###
   * Create
   *
   * Create a new row
   *
   * - data (object) : the data data
   * > id (number) : the new id of the user
  ###

  create: (data) ->

    promise = @query(@table).insert(data)
    @wrap(promise).then (id) -> return id[0]


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

    promise = @_search columns, id: id
    promise.then (rows) -> return rows[0]


  exists: (id) ->

    promise = @_search 'id', id: id
    promise
      .then -> true
      .fail -> false


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

    @_update data,
      id: id


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

    @_delete
      id: id


module.exports = Table
