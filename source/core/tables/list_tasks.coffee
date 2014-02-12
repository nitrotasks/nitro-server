Table = require '../controllers/table'

class ListTasks extends Table

  table: 'list_tasks'

  setup: ->

    @_createTable (table) =>

      table.primary(['listId', 'taskId'])

      table.integer('listId').unsigned()
        .notNullable()
        .references('id').inTable('list')
        .onDelete('cascade')

      table.integer('taskId').unsigned()
        .notNullable()
        .references('id').inTable('task')
        .onDelete('cascade')


  create: (list, task) ->

    @_create 'taskId',
      listId: list
      taskId: task

  read: (list) ->

    promise = @_search 'taskId',
      listId: list

    promise
      .then (rows) ->
        rows.map (row) -> row.taskId
      .catch ->
        return []


  update: ->

    throw new Error 'Cannot update list_tasks'


  destroy: (list, task) ->

    @_delete
      listId: list
      taskId: task


  destroyAll: (list) ->

    @_delete
      listId: list

module.exports = ListTasks
