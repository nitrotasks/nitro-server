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


  create: (listId, taskId) ->

    @_create('taskId', {listId, taskId})

  read: (listId) ->

    @search('taskId', {listId})
    .catch -> []
    .map (row) -> row.taskId

  update: ->

    throw new Error 'Cannot update list_tasks'

  destroy: (listId, taskId) ->

    super {listId, taskId}, true

  destroyAll: (listId) ->

    super {listId}

module.exports = ListTasks
