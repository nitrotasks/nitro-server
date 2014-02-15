Table = require '../controllers/table'

class TimePref extends Table

  table: 'time_pref'
  column: 'id'
  columns: [
    'sort', 'night', 'language',
    'weekStart', 'dateFormat',
    'confirmDelete', 'moveCompleted'
  ]

  setup: ->

    @_createTable (table) =>

      table.integer('id').unsigned()
        .primary()
        .references('userId').inTable('pref')
        .onDelete('cascade')
        .notNullable()

      table.integer('sort').nullable()
      table.integer('night').nullable()
      table.integer('language').nullable()
      table.integer('weekStart').nullable()
      table.integer('dateFormat').nullable()
      table.integer('confirmDelete').nullable()
      table.integer('moveCompleted').nullable()

module.exports = TimePref
