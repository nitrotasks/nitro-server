query = null

module.exports =

  ###
   * Setup
   *
   * Create table
  ###

  setup: (_query) ->

    query = _query

    query """
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
        REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    """

  ###
   * Create
   *
   * Create a new row
  ###

  create: (task) ->

    sql = 'INSERT INTO task SET ?'
    query sql, task



  ###
   * Update
   *
   * Update an existing row
  ###

  update: (task) ->

    sql = 'UPDATE task SET ?'
    query sql, task


  ###
   * Destroy
   *
   * Destroy an existing row
  ###

  destroy: (id) ->

    sql = 'DELETE FROM task WHERE id=?'
    query sql, id



