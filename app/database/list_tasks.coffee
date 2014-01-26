Table = require '../controllers/table'

class ListTasks extends Table

  table: 'list_tasks'

  setup: ->

    @_createTable (table) =>

      table.primary(['listId', 'taskId'])

      table.integer('listId').unsigned()
        .references('id').inTable('list')
        .onDelete('cascade')
        .onUpdate('cascade')

      table.integer('taskId').unsigned()
        .references('id').inTable('task')
        .onDelete('cascade')
        .onUpdate('cascade')

      # CREATE TABLE IF NOT EXISTS `list_tasks` (
      #   `list_id` int(11) unsigned NOT NULL,
      #   `task_id` int(11) unsigned NOT NULL,
      #   PRIMARY KEY (`list_id`,`task_id`),
      #   CONSTRAINT `list_tasks_task_id` FOREIGN KEY (`task_id`)
      #   REFERENCES `task` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
      #   CONSTRAINT `list_tasks_list_id` FOREIGN KEY (`list_id`)
      #   REFERENCES `list` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
      # ) ENGINE=InnoDB DEFAULT CHARSET=latin1;


  create: (list, task) ->

    super
      listId: list
      taskId: task


  read: (list) ->

    promise = @_search 'taskId',
      listId: list

    promise
      .then (rows) ->
        rows.map (row) -> row.taskId
      .fail ->
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
