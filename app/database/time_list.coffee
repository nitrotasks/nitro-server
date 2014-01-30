Table = require '../controllers/table'

class TimeList extends Table

  table: 'time_list'

  setup: ->

    @_createTable (table) =>

      table.integer('id').unsigned()
        .primary()
        .references('id').inTable('list')
        .onDelete('cascade')
        .onUpdate('cascade')
        .notNullable()

      table.integer('name').unsigned()
      table.integer('tasks').unsigned()

module.exports = TimeList