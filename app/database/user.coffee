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

    @query """
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

module.exports = User