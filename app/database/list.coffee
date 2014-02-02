Table = require '../controllers/table'

class List extends Table

  table: 'list'

  setup: ->

    @_createTable (table) =>

      table.increments('id')

      table.integer('userId')
        .index()
        .references('id').inTable('user')
        .onDelete('cascade')
        .notNullable()

      table.string('name', 150).notNullable()

module.exports = List