query = null

module.exports =

  setup: (_query) ->
    query = _query

  clear: (table) ->

    sql = 'DELETE FROM ' + table
    query sql
