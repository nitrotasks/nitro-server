Table = require '../controllers/table'

class ListTasks extends Table

  table: 'list_tasks'
  column: 'taskId'
  columns: ['listId', 'taskId']

  setup: ->

    @_createTable (table) ->

      table.primary(['listId', 'taskId'])

      table.integer('listId').unsigned()
        .notNullable()
        .references('id').inTable('list')
        .onDelete('cascade')

      table.integer('taskId').unsigned()
        .notNullable()
        .references('id').inTable('task')
        .onDelete('cascade')

  create: (taskId, listId) ->

    super { listId, taskId }

  read: (listId) ->

    @search('taskId', { listId })
    .catch -> []
    .map (row) -> row.taskId

  update: (taskId, listId) ->

    @_update { listId }, { taskId }

  destroy: (taskId, listId) ->

    super { taskId, listId }, true

  destroyAll: (listId) ->

    Table::destroy.call this, { listId }

module.exports = ListTasks
