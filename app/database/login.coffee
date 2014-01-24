Table = require '../controllers/table'

class Login extends Table

  table: 'login'

  setup: ->

    @query """
      CREATE TABLE IF NOT EXISTS `login` (
        `user_id`      int(11)        unsigned   NOT NULL,
        `token`        char(64)                  NOT NULL,
        `created_at`   timestamp                 NOT NULL    DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`user_id`,`token`),
        CONSTRAINT `login_user_id` FOREIGN KEY (`user_id`)
        REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    """

  ###
   * Read
   *
   * Retrieve data from an existing row.
   *
   * - id (number) : id of the row
   * - [columns] (array|string) : columns to retrieve
   * > row (object) : the row data
   * ! err_no_row : row cannot be found
  ###

  read: (info, columns='*') ->

    if typeof columns is 'array'
      columns = columns.join ', '

    sql = "SELECT #{ columns } FROM #{ @table } WHERE user_id=? AND token=?"
    args = [info.user_id, info.token]

    @query(sql, args).then (rows) =>
      unless rows.length then throw @ERR_NO_ROW
      return rows[0]


  exists: (info) ->

    sql = "SELECT user_id FROM #{ @table } WHERE user_id=? AND token=?"
    args = [info.user_id, info.token]

    @query(sql, args).then (rows) =>
      return rows.length isnt 0


  update: ->
    throw new Error 'Cannot update login row'


  destroy: (info) ->

    sql = "DELETE FROM #{ @table } WHERE user_id=? and token=?"
    args = [info.user_id, info.token]

    @query sql, args

  destroyAll: Table::destroy

module.exports = Login