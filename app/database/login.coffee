Table = require '../controllers/table'

class Login extends Table

  table: 'login'

  setup: ->

    @_createTable (table) =>

      table.primary(['userId', 'token'])

      table.integer('userId')
        .notNullable()
        .references('id').inTable('user')
        .onDelete('cascade')

      table.string('token', 64).notNullable()
      table.dateTime('created_at').defaultTo @query.raw 'getdate()'

  create: (id, token) ->

    @_create 'userId',
      userId: id
      token: token


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

  read: (id, token, columns) ->

    promise = @_search columns,
      userId: id
      token: token

    promise.then (rows) ->
      return rows[0]


  exists: (id, token) ->

    promise = @_search 'userId',
      userId: id
      token: token

    promise
      .then -> true
      .fail -> false

  update: ->

    throw new Error 'Cannot update login row'


  destroy: (id, token) ->

    @_delete
      userId: id
      token: token


  destroyAll: (id) ->

    @_delete
      userId: id


module.exports = Login