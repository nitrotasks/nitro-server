
class Table

  table: null

  constructor: (@query) ->

  setup: ->


  ###
   * Create
   *
   * Create a new row
   *
   * - data (object) : the data data
   * > id (number) : the new id of the user
  ###

  create: (data) ->

    sql = "INSERT INTO #{ @table } SET ?"

    @query(sql, data).then (info) ->
      return info.insertId


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

  read: (id, columns='*') ->

    if typeof columns is 'array'
      columns = columns.join ', '

    sql = "SELECT #{ columns } FROM #{ @table } WHERE id=?"

    @query(sql, id).then (rows) ->
      unless rows.length then throw new Error 'err_no_row'
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

    sql = "UPDATE #{ @table } SET ? WHERE id=?"

    @query(sql, [data, id]).then (info) ->
      unless info.affectedRows then throw new Error 'err_no_row'
      return info.insertId


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

    sql = "DELETE FROM #{ @table } WHERE id=?"

    @query(sql, id).then (info) ->
      unless info.affectedRows then throw new Error 'err_no_row'
      return true


module.exports = Table
