Table = require '../controllers/table'

class Pref extends Table

  table: 'pref'
  column: 'userId'

  setup: ->

    @_createTable (table) =>

      table.integer('userId').unsigned()
        .primary()
        .references('id').inTable('user')
        .onDelete('cascade')
        .notNullable()

      table.integer('sort').nullable()
      table.integer('night').nullable()
      table.string('language', 5).nullable()
      table.integer('weekStart').nullable()
      table.string('dateFormat', 8).nullable()
      table.integer('confirmDelete').nullable()
      table.integer('moveCompleted').nullable()

  create: (pref) ->

    super(pref).return(pref.userId)

module.exports = Pref
