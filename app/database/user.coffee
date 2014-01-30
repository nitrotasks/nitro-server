Table = require '../controllers/table'

class User extends Table

  table: 'user'

  ###
   * Setup
   *
   * Creates the `user` table if it doesn't already exist
  ###

  setup: ->

    @_createTable (table) =>

      table.increments('id').unsigned()
      table.string('name', 100)
      table.string('email', 100).index()
      table.string('password', 60)
      table.integer('pro').unsigned()
      table.timestamp('created_at').defaultTo @query.raw 'now()'

      # CREATE TABLE IF NOT EXISTS `user` (
      #   `id`           int(11)        unsigned   NOT NULL    AUTO_INCREMENT,
      #   `name`         varchar(100)              NOT NULL,
      #   `email`        varchar(100)              NOT NULL,
      #   `password`     char(60)                  NOT NULL,
      #   `pro`          tinyint(1)     unsigned   NOT NULL,
      #   `created_at`   timestamp                 NOT NULL     DEFAULT CURRENT_TIMESTAMP,
      #   PRIMARY KEY (`id`)
      # ) ENGINE=InnoDB DEFAULT CHARSET=latin1;


  search: (email) ->

    promise = @_search 'id',
      email: email

    promise.then (rows) ->
      return rows[0].id



module.exports = User
