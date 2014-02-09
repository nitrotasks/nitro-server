Promise = require 'bluebird'
Table = require '../controllers/table'

ERR_BAD_TOKEN = 'err_bad_token'

class Register extends Table

  table: 'register'

  setup: ->

    @_createTable (table) =>

      table.increments('id')
      table.string('token', 22).notNullable()
      table.string('name', 100).notNullable()
      table.string('email', 100).notNullable()
      table.string('password', 60).notNullable()
      @_created_at(table)

  create: (data) ->

    super(data).then (id) ->
      return id + '_' + data.token


  read: (token) ->

    match = @_parseToken(token)
    unless match then return Promise.reject ERR_BAD_TOKEN

    promise = @_search ['id', 'name', 'email', 'password'],
      id: match[0]
      token: match[1]

    promise
      .then (rows) -> return rows[0]
      .catch -> throw ERR_BAD_TOKEN


  update: ->

    throw new Error 'Cannot update registration'


module.exports = Register
