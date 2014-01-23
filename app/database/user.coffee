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
      CREATE TABLE IF NOT EXISTS `user` (
        `id`           int(11)        unsigned   NOT NULL    AUTO_INCREMENT,
        `name`         varchar(100)              NOT NULL,
        `email`        varchar(100)              NOT NULL,
        `password`     char(60)                  NOT NULL,
        `pro`          tinyint(1)     unsigned   NOT NULL,
        `created_at`   timestamp                 NOT NULL     DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    """

  ###
   * Create
   *
   * Create a new row
  ###

  create: (user) ->

    sql = 'INSERT INTO user SET ?'
    query(sql, user).then (info) ->
      return info.insertId


  ###
   * Read
   *
   * Read a row
  ###

  read: (id, attrs='*') ->

    if attrs is '*'
      sql = 'SELECT * FROM user WHERE id=?'
      args = id

    else
      sql = 'SELECT ? FROM user WHERE id=?'
      args = [attrs, id]

    query(sql, args).then (rows) ->
      return rows[0]


  ###
   * Update
   *
   * Update an existing row
  ###

  update: (user) ->

    sql = 'UPDATE user SET ?'
    query sql, user


  ###
   * Destroy
   *
   * Destroy an existing row
  ###

  destroy: (id) ->

    sql = 'DELETE FROM user WHERE id=?'
    query sql, id



