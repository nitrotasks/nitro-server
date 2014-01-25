Q = require 'kew'
Table = require '../controllers/table'

class Register extends Table

  table: 'register'

  setup: ->

    @_createTable (table) =>

      table.increments('id').unsigned()
      table.string('token', 22)
      table.string('name', 100)
      table.string('email', 100)
      table.string('password', 60)
      table.timestamp('created_at').defaultTo @query.raw 'now()'

      # CREATE TABLE IF NOT EXISTS `register` (
      #   `id`           int(11)        unsigned   NOT NULL    AUTO_INCREMENT,
      #   `token`        char(22)                  NOT NULL,
      #   `name`         varchar(100)              NOT NULL,
      #   `email`        varchar(100)              NOT NULL,
      #   `password`     char(60)                  NOT NULL,
      #   `created_at`   timestamp                 NOT NULL    DEFAULT CURRENT_TIMESTAMP,
      #   PRIMARY KEY (`id`,`token`)
      # ) ENGINE=InnoDB DEFAULT CHARSET=latin1;

  create: (data) ->

    super(data).then (id) ->
      return id + '_' + data.token


  read: (token) ->

    match = @_parseToken(token)
    unless match then return Q.reject('err_invalid_token')

    promise = @_search ['id', 'name', 'email', 'password'],
      id: match[0]
      token: match[1]

    promise.then (rows) ->
      return rows[0]


  update: ->

    throw new Error 'Cannot update registration'


module.exports = Register
