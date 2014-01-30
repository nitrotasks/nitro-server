Table = require '../controllers/table'

class TimePref extends Table

  table: 'time_pref'

  setup: ->

    @_createTable (table) =>

      table.integer('id').unsigned()
        .primary()
        .references('userId').inTable('pref')
        .onDelete('cascade')
        .onUpdate('cascade')
        .notNullable()

      table.integer('sort').unsigned()
      table.integer('night').unsigned()
      table.integer('language').unsigned()
      table.integer('weekStart').unsigned()
      table.integer('dateFormat').unsigned()
      table.integer('confirmDelete').unsigned()
      table.integer('moveCompleted').unsigned()

module.exports = TimePref