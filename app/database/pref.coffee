Table = require '../controllers/table'

class Pref extends Table

  table: 'pref'

  setup: ->

    @createTable (table) =>

      table.integer('user_id').unsigned()
        .primary()
        .references('id').inTable('user')
        .onDelete('cascade')
        .onUpdate('cascade')

      table.boolean('sort').unsigned()

      table.boolean('night').unsigned()

      table.string('language', 5)

      table.boolean('weekStart').unsigned()

      table.string('dateFormat', 8)

      table.boolean('confirmDelete').unsigned()

      table.boolean('moveCompleted').unsigned()

      console.log table.toString()

      # CREATE TABLE IF NOT EXISTS `pref` (
      #   `user_id`       int(11)    unsigned NOT NULL      AUTO_INCREMENT,
      #   `sort`          tinyint(1) unsigned DEFAULT NULL,
      #   `night`         tinyint(1) unsigned DEFAULT NULL,
      #   `language`      varchar(5)          DEFAULT '',
      #   `weekStart`     tinyint(1) unsigned DEFAULT NULL,
      #   `dateFormat`    char(8)             DEFAULT NULL,
      #   `confirmDelete` tinyint(1) unsigned DEFAULT NULL,
      #   `moveCompleted` tinyint(1) unsigned DEFAULT NULL,
      #   PRIMARY KEY (`user_id`),
      #   CONSTRAINT `pref_user_id` FOREIGN KEY (`user_id`)
      #   REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
      # ) ENGINE=InnoDB DEFAULT CHARSET=latin1;


  ###
   * Read
   *
   * Retrieve data from an existing row.
   *
   * - id (number) : id of the row
   * - [columns] (array|string) : columns to retrieve
   * > row (object) : the row data
   * ! err_no_row : row cannot be found
  ###

  read: (id, columns) ->

    promise = @exec @query(@table)
      .select()
      .column(columns)
      .where('user_id', id)

    promise.then (rows) =>
      unless rows.length then throw @ERR_NO_ROW
      return rows[0]


  ###
   * Update
   *
   * Update attributes in an existing row.
   *
   * - id (number) : the id of the row
   * - data (object) : attributes to set in the row
   * > id (number)
   * ! err_no_row : row cannot be found
  ###

  update: (id, data) ->

    promise = @exec @query(@table)
      .where('user_id', id)
      .update(data)

    promise.then (rows) =>
      unless rows then throw @ERR_NO_ROW
      return rows


  ###
   * Destroy
   *
   * Destroy an existing row.
   *
   * - id (number) : id of row to destroy
   * > true
   * ! err_no_row : row cannot be found
  ###

  destroy: (id) ->

    promise = @exec @query(@table)
      .where('user_id', id)
      .del()

    promise.then (rows) =>
      unless rows then throw @ERR_NO_ROW
      return true


module.exports = Pref
