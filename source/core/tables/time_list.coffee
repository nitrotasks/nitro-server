Table = require '../controllers/table'

class TimeList extends Table

  table: 'time_list'
  column: 'id'
  columns: ['name', 'tasks']

  setup: ->

    @_createTable (table) =>

      table.integer('id').unsigned()
        .primary()
        .references('id').inTable('list')
        .onDelete('cascade')
        .notNullable()

      table.integer('name').nullable()
      table.integer('tasks').nullable()

module.exports = TimeList