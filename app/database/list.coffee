Table = require '../controllers/table'

class List extends Table

  table: 'list'

  setup: ->

    @query """
      CREATE TABLE IF NOT EXISTS `list` (
        `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
        `user_id` int(11) unsigned NOT NULL,
        `name` varchar(150) NOT NULL DEFAULT '',
        PRIMARY KEY (`id`),
        CONSTRAINT `list_user_id` FOREIGN KEY (`user_id`)
        REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    """


module.exports = List