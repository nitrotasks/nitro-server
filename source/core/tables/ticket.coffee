Table = require '../controllers/table'

class Ticket extends Table

  table: 'ticket'
  column: 'userId'
  columns: ['userId', 'token', 'created_at']

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

  read: (userId, token) ->

    @search null, { userId, token }
    .then (rows) -> return rows[0]

  readAll: (userId) ->

    @search null, { userId }

  update: ->

    throw new Error 'Cannot update ticket'

  destroy: (userId, token) ->

    super { userId, token }

  destroyAll: (userId) ->

    Table::destroy.call this, { userId }


module.exports = Ticket
