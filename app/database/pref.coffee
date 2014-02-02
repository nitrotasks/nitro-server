Table = require '../controllers/table'

class Pref extends Table

  table: 'pref'

  setup: ->

    @_createTable (table) =>

      table.integer('userId').unsigned()
        .primary()
        .references('id').inTable('user')
        .onDelete('cascade')
        .notNullable()

      table.integer('sort').nullable()
      table.integer('night').nullable()
      table.string('language', 5).nullable()
      table.integer('weekStart').nullable()
      table.string('dateFormat', 8).nullable()
      table.integer('confirmDelete').nullable()
      table.integer('moveCompleted').nullable()

  create: (data) ->

    @_create('userId', data)


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

    promise = @_search columns,
      userId: id

    promise.then (rows) =>
      return rows[0]


  ###
   * Update
   *
   * Update attributes in an existing row.
   * Does not care if the row does not exist
   *
   * - id (number) : the id of the user
   * - data (object) : attributes to set in the row
   * > id (number)
  ###

  update: (id, data) ->

    promise = @_update data,
      userId: id


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
      userId: id


module.exports = Pref
