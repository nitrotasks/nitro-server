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

      table.bigInteger('listId').unsigned()
      table.bigInteger('name').unsigned()
      table.bigInteger('notes').unsigned()
      table.bigInteger('priority').unsigned()
      table.bigInteger('completed').unsigned()
      table.bigInteger('date').unsigned()

module.exports = TimeTask