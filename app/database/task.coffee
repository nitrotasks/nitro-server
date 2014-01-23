Table = require '../controllers/table'

class Task extends Table

  table: 'task'

  ###
   * Setup
   *
   * Create table
  ###

  setup: ->

    @query """
      CREATE TABLE IF NOT EXISTS `task` (
        `id`          int(11)         unsigned   NOT NULL    AUTO_INCREMENT,
        `user_id`     int(11)         unsigned   NOT NULL,
        `list_id`     int(11)         unsigned   NOT NULL,
        `name`        varchar(150)               NOT NULL    DEFAULT '',
        `notes`       varchar(400)               NOT NULL    DEFAULT '',
        `priority`    tinyint(4)      unsigned   NOT NULL,
        `completed`   bigint(20)      unsigned   NOT NULL,
        `date`        bigint(20)      unsigned   NOT NULL,
        PRIMARY KEY (`id`,`user_id`),
        CONSTRAINT `task_user_id` FOREIGN KEY (`user_id`)
        REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
        CONSTRAINT `task_list_id` FOREIGN KEY (`list_id`)
        REFERENCES `list` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    """

module.exports = Task

