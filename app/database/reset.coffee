Q = require 'kew'
Table = require '../controllers/table'

parseToken = (token) ->
  match = token.match(/^(\d+)_(\w+)$/)
  if match is null then return null
  return [match[1], match[2]]

class Reset extends Table

  table: 'reset'

  setup: ->

    @query """
      CREATE TABLE IF NOT EXISTS `reset` (
        `user_id`      int(11)        unsigned   NOT NULL,
        `token`        char(22)                  NOT NULL,
        `created_at`   timestamp                 NOT NULL    DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`user_id`,`token`),
        CONSTRAINT `reset_user_id` FOREIGN KEY (`user_id`)
        REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    """

  create: (data) ->

    super(data).then ->
      return data.user_id + '_' + data.token


  read: (token) ->

    match = parseToken(token)
    unless match then return Q.reject('err_invalid_token')

    sql = 'SELECT user_id FROM reset WHERE user_id=? AND token=?'

    @query(sql, match).then (rows) =>
      unless rows.length then throw @ERR_NO_ROW
      return rows[0].user_id


  update: ->

    throw new Error 'Cannot update a reset token'


  destroy: (token) ->

    match = parseToken(token)
    unless match then return Q.reject('err_invalid_token')

    sql = 'DELETE FROM reset WHERE user_id=? AND token=?'

    @query(sql, match).then (info) =>
      unless info.affectedRows then throw @ERR_NO_ROW
      return true

module.exports = Reset