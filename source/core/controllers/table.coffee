class Table

  ###
   * Table (string)
   *
   * This should store the table name
  ###

  table: null
  column: 'id'

  ###
   * Constants
  ###

  ERR_NO_ROW: 'err_no_row'


  ###
   * Table Constructor
   *
   * - knex (function) : the Knex builder
  ###

  constructor: (@knex) ->


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
   * (private) Create Table
   *
   * Creates a table if it does not already exist
   *
   * - fn (function) : will be passed to knex.schema.createTable
  ###

  _createTable: (fn) ->

    @knex.schema.hasTable @table
      .then (exists) =>
        return if exists
        @knex.schema.createTable(@table, fn)


  ###
   * (private) Drop Table
  ###

  _dropTable: ->

    @knex.schema.dropTable(@table)


  ###
   * (private) Parse Token
  ###

  _parseToken: (token) ->
    match = token.match(/^(\d+)_(\w+)$/)
    if match is null then return null
    return [match[1], match[2]]


  ###
   * (private) Create
  ###

  _create: (returning, data) ->

    @knex @table
      .returning returning
      .insert data
      .then (id) -> id[0]


  ###
   * (private) Update
  ###

  _update: (data, where) ->

    @knex @table
      .update data
      .where where
      .then (rows) =>
        unless rows then throw @ERR_NO_ROW
        return rows


  ###
   * Search
   *
   * - columns (string|array<string>)
   * - data (object)
   * > array
   * ! err_no_row
  ###

  search: (columns, data) ->

    @knex @table
      .select()
      .column columns
      .where data
      .then (rows) =>
        unless rows.length then throw @ERR_NO_ROW
        return rows


  ###
   * Create
   *
   * Create a new row
   *
   * - data (object) : the data data
   * > id (number) : the new id of the user
  ###

  create: (data) ->

    @_create @column, data


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

    obj = {}
    obj[@column] = id
    @search(columns, obj)
      .then (rows) -> rows[0]


  ###
   * Table::exists
   *
   * Check if a row exists in the database.
   * If obj is not an object, then it will match it against @column
   *
   * - obj (dynamic) : value to check for
   * > boolean
  ###

  exists: (obj) ->

    if typeof obj isnt 'object'
      _obj = obj
      obj = {}
      obj[@column] = _obj

    @search(@column, obj)
      .return(true)
      .catch -> false



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

    obj = {}
    obj[@column] = id
    @_update data, obj


  ###
   * Destroy
   *
   * Destroy an existing row.
   *
   * - id (number) : id of row to destroy
   * - strict (boolean) : throw an error if the row didn't exist
   * > true
   * ! err_no_row : row cannot be found
  ###

  destroy: (obj, strict) ->

    if typeof obj isnt 'object'
      _obj = obj
      obj = {}
      obj[@column] = _obj

    @knex @table
      .del()
      .where(obj)
      .then (rows) ->
        success = rows > 0
        throw ERR_NO_ROW if strict and not success
        return success


module.exports = Table
