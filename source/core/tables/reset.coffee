Table = require '../controllers/table'

class Reset extends Table

  table: 'reset'
  column: 'userId'
  columns: ['userId', 'token', 'created_at']

  setup: ->

    @_createTable (table) =>

      table.integer('userId').unsigned()
        .notNullable()
        .references('id').inTable('user')
        .onDelete('cascade')
        .primary()

      table.string('token', 22).notNullable()
      table.timestamp('created_at').defaultTo @knex.raw 'now()'

  create: (userId, token) ->

    super({ userId, token }).return(token)

  read: (token) ->

    @search null, { token }
    .then (rows) -> rows[0]

  update: ->

    throw new Error('err_not_allowed')

  destroy: (token) ->

    super { token }

  destroyAll: (userId) ->

    Table::destroy.call(this, userId)

module.exports = Reset
