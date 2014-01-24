Q = require 'kew'
Table = require '../controllers/table'

parseToken = (token) ->
  match = token.match(/^(\d+)_(\w+)$/)
  if match is null then return null
  return [match[1], match[2]]

class Register extends Table

  table: 'register'

  setup: ->

    @query """
      CREATE TABLE IF NOT EXISTS `register` (
        `id`           int(11)        unsigned   NOT NULL    AUTO_INCREMENT,
        `token`        char(22)                  NOT NULL,
        `name`         varchar(100)              NOT NULL,
        `email`        varchar(100)              NOT NULL,
        `password`     char(60)                  NOT NULL,
        `created_at`   timestamp                 NOT NULL    DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`,`token`)
      ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    """

  create: (data) ->

    super(data).then (id) ->
      return id + '_' + data.token


  read: (token) ->

    match = parseToken(token)
    unless match then return Q.reject('err_invalid_token')

    sql = 'SELECT name, email, password FROM register WHERE id=? AND token=?'

    @query(sql, match).then (rows) =>
      unless rows.length then throw @ERR_NO_ROW
      return rows[0]


  update: ->

    throw new Error 'Cannot update registration'

  destroy: (token) ->

    match = parseToken(token)
    unless match then return Q.reject('err_invalid_token')

    id = match[0]
    super(id)



module.exports = Register