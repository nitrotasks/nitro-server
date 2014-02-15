Table = require '../controllers/table'

class Login extends Table

  table: 'login'
  column: 'userId'
  columns: ['userId', 'token']

  setup: ->

    @_createTable (table) =>

      table.primary(['userId', 'token'])

      table.integer('userId').unsigned()
        .notNullable()
        .references('id').inTable('user')
        .onDelete('cascade')

      table.string('token', 64).notNullable()
      table.timestamp('created_at').defaultTo @knex.raw 'now()'

  create: (userId, token) ->

    @_create('userId', {userId, token}).return(userId)


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

  read: (userId, token) ->

    @search null, { userId, token }
    .then (rows) -> return rows[0]

  readAll: (userId) ->

    @search null, { userId }

  update: ->

    throw new Error 'Cannot update login row'

  destroy: (userId, token) ->

    super { userId, token }

  destroyAll: (userId) ->

    Table::destroy.call this, { userId }


module.exports = Login
