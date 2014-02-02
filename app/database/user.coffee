Table = require '../controllers/table'

class User extends Table

  table: 'user'

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
      table.integer('pro').notNullable()
      @_created_at(table)


  search: (email) ->

    promise = @_search 'id',
      email: email

    promise.then (rows) ->
      return rows[0].id



module.exports = User
