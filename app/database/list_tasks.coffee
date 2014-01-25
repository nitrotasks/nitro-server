Table = require '../controllers/table'

class ListTasks extends Table

  table: 'list_tasks'

  setup: ->

    @createTable (table) =>

      table.primary(['list_id', 'task_id'])

      table.integer('list_id').unsigned()
        .references('id').inTable('list')
        .onDelete('cascade')
        .onUpdate('cascade')

      table.integer('task_id').unsigned()
        .references('id').inTable('task')
        .onDelete('cascade')
        .onUpdate('cascade')

      console.log table.toString()

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

    @exec @query(@table)
      .insert
        list_id: list
        task_id: task


  read: (list) ->

    promise = @exec @query(@table)
      .select('task_id')
      .where('list_id', list)

    promise.then (rows) ->
      rows.map (row) -> row.task_id


  update: ->

    throw new Error 'Cannot update list_tasks'


  destroy: (list, task) ->

    @exec @query(@table)
      .del()
      .where
        list_id: list
        task_id: task


  destroyAll: (list) ->

    @exec @query(@table)
      .del()
      .where 'list_id', list


module.exports = ListTasks
