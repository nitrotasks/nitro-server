Table = require '../controllers/table'

class Pref extends Table

  table: 'pref'

  setup: ->

    @query """
      CREATE TABLE IF NOT EXISTS `pref` (
        `id`                int(11)     unsigned NOT NULL      AUTO_INCREMENT,
        `sort`              tinyint(1)  unsigned DEFAULT NULL,
        `night`             tinyint(1)  unsigned DEFAULT NULL,
        `language`          varchar(5)           DEFAULT '',
        `weekStart`         tinyint(1)  unsigned DEFAULT NULL,
        `dateFormat`        char(8)              DEFAULT NULL,
        `comfirmDelete`     tinyint(1)  unsigned DEFAULT NULL,
        `completedDuration` tinyint(1)  unsigned DEFAULT NULL,
        PRIMARY KEY (`id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    """

module.exports = Pref