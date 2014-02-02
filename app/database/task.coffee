Table = require '../controllers/table'

class Task extends Table

  table: 'task'

  ###
   * Setup
   *
   * Create table
  ###

  setup: ->

    @_createTable (table) =>

      table.increments('id')

      table.integer('userId')
        .index()
        .references('id').inTable('user')
        .notNullable()

      table.integer('listId').unsigned()
        .references('id').inTable('list')
        .onDelete('cascade')
        .notNullable()

      table.string('name', 150).nullable()
      table.string('notes', 400).nullable()
      table.integer('priority').nullable()
      table.integer('completed').nullable()
      table.integer('date').nullable()

module.exports = Task

