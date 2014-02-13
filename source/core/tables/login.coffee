Table = require '../controllers/table'

class Login extends Table

  table: 'login'

  setup: ->

    @_createTable (table) =>

      table.primary(['userId', 'token'])

      table.integer('userId').unsigned()
        .notNullable()
        .references('id').inTable('user')
        .onDelete('cascade')

      table.string('token', 64).notNullable()
      table.timestamp('created_at').defaultTo @knex.raw 'now()'

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

    promise = @search columns,
      userId: id
      token: token

    promise.then (rows) ->
      return rows[0]


  exists: (id, token) ->

    promise = @search 'userId',
      userId: id
      token: token

    promise
      .return(true)
      .catch -> false

  update: ->

    throw new Error 'Cannot update login row'


  destroy: (id, token) ->

    super
      userId: id
      token: token


  destroyAll: (id) ->

    super
      userId: id


module.exports = Login