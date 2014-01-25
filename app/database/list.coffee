Table = require '../controllers/table'

class List extends Table

  table: 'list'

  setup: ->

    @createTable (table) =>

      table.increments('id').unsigned()

      table.integer('user_id').unsigned()
        .index()
        .references('id').inTable('user')
        .onDelete('cascade')
        .onUpdate('cascade')

      table.string('name', 150)

      console.log table.toString()


      # CREATE TABLE IF NOT EXISTS `list` (
      #   `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
      #   `user_id` int(11) unsigned NOT NULL,
      #   `name` varchar(150) NOT NULL DEFAULT '',
      #   PRIMARY KEY (`id`),
      #   CONSTRAINT `list_user_id` FOREIGN KEY (`user_id`)
      #   REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
      # ) ENGINE=InnoDB DEFAULT CHARSET=latin1;


module.exports = List