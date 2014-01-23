query = null

module.exports =

  ###
   * Setup
   *
   * Creates the `user` table if it doesn't already exist
   *
   * - _query (function) : to be used to execute sql
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
   * Create a new user
   *
   * - user (object) : the users data
   * > id (number) : the new id of the user
  ###

  create: (user) ->

    sql = 'INSERT INTO user SET ?'
    query(sql, user).then (info) ->
      return info.insertId


  ###
   * Read
   *
   * Retrieve an existing users information.
   *
   * - id (number) : id of the user
   * - [attrs] (array|string) : columns to retrieve
   * > row (object) : the users information
   * ! err_no_user : if it cannot find the user id
  ###

  read: (id, attrs='*') ->

    if attrs is '*'
      sql = 'SELECT * FROM user WHERE id=?'
      args = id

    else
      sql = 'SELECT ? FROM user WHERE id=?'
      args = [attrs, id]

    query(sql, args).then (rows) ->
      unless rows.length
        throw new Error('err_no_user')

      return rows[0]


  ###
   * Update
   *
   * Update an existing user.
   *
   * - id (number) : the users id
   * - user (object) : changes to be made to the user
   * > id (number)
   * ! err_no_user : if the user cannot be found
  ###

  update: (id, user) ->

    sql = 'UPDATE user SET ? WHERE id=?'
    query(sql, [user, id]).then (info) ->
      if info.affectedRows is 0
        throw new Error('err_no_user')
      return info.insertId


  ###
   * Destroy
   *
   * Destroy an existing user.
   *
   * - id (number) : id of user to destroy
   * > true
   * ! err_no_user : if user cannot be found
  ###

  destroy: (id) ->

    sql = 'DELETE FROM user WHERE id=?'
    query(sql, id).then (info) ->
      if info.affectedRows is 0
        throw new Error('err_no_user')
      return true



