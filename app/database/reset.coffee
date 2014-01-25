Q = require 'kew'
Table = require '../controllers/table'

parseToken = (token) ->
  match = token.match(/^(\d+)_(\w+)$/)
  if match is null then return null
  return [match[1], match[2]]

class Reset extends Table

  table: 'reset'

  setup: ->

    @createTable (table) =>

      table.primary(['user_id', 'token'])

      table.integer('user_id').unsigned()
        .references('id').inTable('user')
        .onDelete('cascade')
        .onUpdate('cascade')

      table.string('token', 22)

      table.timestamp('created_at').defaultTo @query.raw 'now()'

      console.log table.toString()

      # CREATE TABLE IF NOT EXISTS `reset` (
      #   `user_id`      int(11)        unsigned   NOT NULL,
      #   `token`        char(22)                  NOT NULL,
      #   `created_at`   timestamp                 NOT NULL    DEFAULT CURRENT_TIMESTAMP,
      #   PRIMARY KEY (`user_id`,`token`),
      #   CONSTRAINT `reset_user_id` FOREIGN KEY (`user_id`)
      #   REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
      # ) ENGINE=InnoDB DEFAULT CHARSET=latin1;

  create: (id, token) ->

    super({ user_id: id, token: token }).then ->
      return id + '_' + token


  read: (token) ->

    match = parseToken(token)
    unless match then return Q.reject('err_invalid_token')

    promise = @exec @query(@table)
      .select('user_id')
      .where
        user_id: match[0]
        token: match[1]

    promise.then (rows) =>
      unless rows.length then throw @ERR_NO_ROW
      return rows[0].user_id


  update: ->

    throw new Error 'Cannot update a reset token'


  destroy: (token) ->

    match = parseToken(token)
    unless match then return Q.reject('err_invalid_token')

    promise = @exec @query(@table)
      .del()
      .where
        user_id: match[0]
        token: match[1]

    promise.then (rows) =>
      unless rows then throw @ERR_NO_ROW
      return true


module.exports = Reset