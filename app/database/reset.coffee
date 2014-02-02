Q = require 'kew'
Table = require '../controllers/table'

ERR_BAD_TOKEN = 'err_bad_token'

class Reset extends Table

  table: 'reset'

  setup: ->

    @_createTable (table) =>

      table.primary(['userId', 'token'])

      table.integer('userId').unsigned()
        .notNullable()
        .references('id').inTable('user')
        .onDelete('cascade')

      table.string('token', 22).notNullable()
      @_created_at(table)

  create: (id, token) ->

    promise = @_create 'userId',
      userId: id
      token: token

    promise.then ->
      return id + '_' + token


  read: (token) ->

    match = @_parseToken(token)
    unless match then return Q.reject ERR_BAD_TOKEN

    promise = @_search 'userId',
      userId: match[0]
      token: match[1]

    promise
      .then (rows) -> return rows[0].userId
      .fail -> throw ERR_BAD_TOKEN

  update: ->

    throw new Error 'Cannot update a reset token'


  destroy: (token) ->

    match = @_parseToken(token)
    unless match then return Q.reject ERR_BAD_TOKEN

    @_delete
      userId: match[0]
      token: match[1]


module.exports = Reset