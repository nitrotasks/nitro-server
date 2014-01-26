Q = require 'kew'
Table = require '../controllers/table'


class Reset extends Table

  table: 'reset'

  setup: ->

    @_createTable (table) =>

      table.primary(['userId', 'token'])

      table.integer('userId').unsigned()
        .references('id').inTable('user')
        .onDelete('cascade')
        .onUpdate('cascade')

      table.string('token', 22)
      table.timestamp('created_at').defaultTo @query.raw 'now()'

      # CREATE TABLE IF NOT EXISTS `reset` (
      #   `userId`      int(11)        unsigned   NOT NULL,
      #   `token`        char(22)                  NOT NULL,
      #   `created_at`   timestamp                 NOT NULL    DEFAULT CURRENT_TIMESTAMP,
      #   PRIMARY KEY (`userId`,`token`),
      #   CONSTRAINT `reset_userId` FOREIGN KEY (`userId`)
      #   REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
      # ) ENGINE=InnoDB DEFAULT CHARSET=latin1;


  create: (id, token) ->

    super({ userId: id, token: token }).then ->
      return id + '_' + token


  read: (token) ->

    match = @_parseToken(token)
    unless match then return Q.reject('err_invalid_token')

    promise = @_search 'userId',
      userId: match[0]
      token: match[1]

    promise.then (rows) ->
      return rows[0].userId


  update: ->

    throw new Error 'Cannot update a reset token'


  destroy: (token) ->

    match = @_parseToken(token)
    unless match then return Q.reject('err_invalid_token')

    @_delete
      userId: match[0]
      token: match[1]


module.exports = Reset