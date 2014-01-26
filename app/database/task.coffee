Table = require '../controllers/table'

class Task extends Table

  table: 'task'

  ###
   * Setup
   *
   * Create table
  ###

  setup: ->

    @_createTable (table) =>

      table.increments('id').unsigned()

      table.integer('userId').unsigned()
        .index()
        .references('id').inTable('user')
        .onDelete('cascade')
        .onUpdate('cascade')
        .notNullable()

      table.integer('listId').unsigned()
        .references('id').inTable('list')
        .onDelete('cascade')
        .onUpdate('cascade')
        .notNullable()

      table.string('name', 150)
      table.string('notes', 400)
      table.integer('priority').unsigned()
      table.bigInteger('completed').unsigned()
      table.bigInteger('date').unsigned()

      # CREATE TABLE IF NOT EXISTS `task` (
      #   `id`          int(11)         unsigned   NOT NULL    AUTO_INCREMENT,
      #   `userId`     int(11)         unsigned   NOT NULL,
      #   `listId`     int(11)         unsigned   NOT NULL,
      #   `name`        varchar(150)               NOT NULL    DEFAULT '',
      #   `notes`       varchar(400)               NOT NULL    DEFAULT '',
      #   `priority`    tinyint(4)      unsigned   NOT NULL,
      #   `completed`   bigint(20)      unsigned   NOT NULL,
      #   `date`        bigint(20)      unsigned   NOT NULL,
      #   PRIMARY KEY (`id`,`userId`),
      #   CONSTRAINT `task_userId` FOREIGN KEY (`userId`)
      #   REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
      #   CONSTRAINT `task_listId` FOREIGN KEY (`listId`)
      #   REFERENCES `list` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
      # ) ENGINE=InnoDB DEFAULT CHARSET=latin1;

module.exports = Task

