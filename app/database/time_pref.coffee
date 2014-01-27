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

      table.bigInteger('sort').unsigned()
      table.bigInteger('night').unsigned()
      table.bigInteger('language').unsigned()
      table.bigInteger('weekStart').unsigned()
      table.bigInteger('dateFormat').unsigned()
      table.bigInteger('confirmDelete').unsigned()
      table.bigInteger('moveCompleted').unsigned()

module.exports = TimePref