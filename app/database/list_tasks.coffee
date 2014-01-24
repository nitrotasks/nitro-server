Table = require '../controllers/table'

class ListTasks extends Table

  table: 'list_tasks'

  setup: ->

    @query """
      CREATE TABLE IF NOT EXISTS `list_tasks` (
        `list_id` int(11) unsigned NOT NULL,
        `task_id` int(11) unsigned NOT NULL,
        PRIMARY KEY (`list_id`,`task_id`),
        CONSTRAINT `list_tasks_task_id` FOREIGN KEY (`task_id`)
        REFERENCES `task` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
        CONSTRAINT `list_tasks_list_id` FOREIGN KEY (`list_id`)
        REFERENCES `list` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    """


  create: (list, task) ->

    sql = "INSERT INTO #{ @table } (list_id, task_id) VALUES (?, ?)"
    args = [list, task]

    @query sql, args

  read: (list) ->

    sql = "SELECT task_id FROM #{ @table } WHERE list_id=?"
    args = list

    @query(sql, args).then (rows) ->
      rows.map (row) -> row.task_id


  update: ->

    throw new Error 'Cannot update list_tasks'


  destroy: (list, task) ->

    sql = "DELETE FROM #{ @table } WHERE list_id=? AND task_id=?"
    args = [list, task]

    @query sql, args


  destroyAll: (list) ->

    sql = "DELETE FROM #{ @table } WHERE list_id=?"
    args = list

    @query sql, args

module.exports = ListTasks
