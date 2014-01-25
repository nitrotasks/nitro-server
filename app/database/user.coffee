Table = require '../controllers/table'

class User extends Table

  table: 'user'

  ###
   * Setup
   *
   * Creates the `user` table if it doesn't already exist
   *
   * - _query (function) : to be used to execute sql
  ###

  setup: ->

    @createTable (table) =>

      table.increments('id').unsigned()
      table.string('name', 100)
      table.string('email', 100)
      table.string('password', 60)
      table.boolean('pro').unsigned()
      table.timestamp('created_at').defaultTo @query.raw 'now()'
      console.log table.toString()

  #   CREATE TABLE IF NOT EXISTS `user` (
  #     `id`           int(11)        unsigned   NOT NULL    AUTO_INCREMENT,
  #     `name`         varchar(100)              NOT NULL,
  #     `email`        varchar(100)              NOT NULL,
  #     `password`     char(60)                  NOT NULL,
  #     `pro`          tinyint(1)     unsigned   NOT NULL,
  #     `created_at`   timestamp                 NOT NULL     DEFAULT CURRENT_TIMESTAMP,
  #     PRIMARY KEY (`id`)
  #   ) ENGINE=InnoDB DEFAULT CHARSET=latin1;

module.exports = User