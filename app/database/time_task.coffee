Table = require '../controllers/table'

class TimeTask extends Table

  table: 'time_task'

  setup: ->

    @_createTable (table) =>

      table.integer('id').unsigned()
        .primary()
        .references('id').inTable('task')
        .onDelete('cascade')
        .onUpdate('cascade')
        .notNullable()

      table.integer('listId').unsigned()
      table.integer('name').unsigned()
      table.integer('notes').unsigned()
      table.integer('priority').unsigned()
      table.integer('completed').unsigned()
      table.integer('date').unsigned()

module.exports = TimeTask