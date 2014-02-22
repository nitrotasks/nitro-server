Table = require '../controllers/table'

class User extends Table

  table: 'user'
  column: 'id'
  columns: [
    'id', 'name', 'email', 'password', 'pro',
    'created_at', 'reset_password_token', 'reset_password_sent_at'
  ]

  ###
   * Setup
   *
   * Creates the `user` table if it doesn't already exist
  ###

  setup: ->

    @_createTable (table) =>

      table.increments('id')
      table.string('name', 100).notNullable()
      table.string('email', 100).index().unique().notNullable()
      table.string('password', 60).notNullable()
      table.integer('pro').defaultTo(0).notNullable()
      table.timestamp('created_at').defaultTo @knex.raw 'now()'

module.exports = User
