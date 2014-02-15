Table = require '../controllers/table'

class TimeTask extends Table

  table: 'time_task'
  column: 'id'
  columns: ['listId', 'name', 'notes', 'priority', 'completed', 'date']

  setup: ->

    @_createTable (table) =>

      table.integer('id').unsigned()
        .primary()
        .references('id').inTable('task')
        .onDelete('cascade')
        .notNullable()

      table.integer('listId').nullable()
      table.integer('name').nullable()
      table.integer('notes').nullable()
      table.integer('priority').nullable()
      table.integer('completed').nullable()
      table.integer('date').nullable()

module.exports = TimeTask