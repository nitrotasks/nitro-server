FUNCTION = 'function'

module.exports =

  function: (obj) ->
    typeof obj is FUNCTION

  array: (obj) ->
    Array.isArray obj
