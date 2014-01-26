Table = require '../controllers/table'

class Login extends Table

  table: 'login'

  setup: ->

    @_createTable (table) =>

      table.primary(['userid', 'token'])

      table.integer('userId').unsigned()
        .references('id').inTable('user')
        .onDelete('cascade')
        .onUpdate('cascade')

      table.string('token', 64)
      table.timestamp('created_at').defaultTo @query.raw 'now()'

      # CREATE TABLE IF NOT EXISTS `login` (
      #   `userId`      int(11)        unsigned   NOT NULL,
      #   `token`        char(64)                  NOT NULL,
      #   `created_at`   timestamp                 NOT NULL    DEFAULT CURRENT_TIMESTAMP,
      #   PRIMARY KEY (`userId`,`token`),
      #   CONSTRAINT `login_userId` FOREIGN KEY (`userId`)
      #   REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
      # ) ENGINE=InnoDB DEFAULT CHARSET=latin1;


  create: (id, token) ->

    super
      userId: id
      token: token


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

  read: (id, token, columns) ->

    promise = @_search columns,
      userId: id
      token: token

    promise.then (rows) ->
      return rows[0]


  exists: (id, token) ->

    promise = @_search 'userId',
      userId: id
      token: token

    promise.then @_true, @_false

  update: ->

    throw new Error 'Cannot update login row'


  destroy: (id, token) ->

    @_delete
      userId: id
      token: token


  destroyAll: (id) ->

    @_delete
      userId: id


module.exports = Login