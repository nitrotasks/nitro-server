# Hold all the definitions
definitions = {}

# Get a definition
getDef = (name) ->
  def = definitions[name]
  if not def then return checkType(name)
  return def

# Check an object is of a native type
check = (obj, type) ->
  return typeof obj is type

# Curried version of `check`
checkType = (type) ->
  return (obj) -> return typeof obj is type

# Create a new type definition
define = (name, type, details) ->

  if definitions[name]
    throw new Error('Definition already defined: ' + name)

  typeCheck = getDef(type)

  # Simplest definition
  if not details
    return definitions[name] = checkType(type)

  # Checking function
  if check details, 'function'
    return definitions[name] = details

  # Inheriting properties from other definitions
  inherit = details.inherit
  if typeof inherit is 'function'
    inherit = (obj) ->
      return definitions[details.inherit(obj)](obj)
  else if typeof inherit is 'string'
    inherit = definitions[inherit]

  # Check object/array props
  prop = details.prop
  if prop then prop = getDef(prop)

  # Checking object/array keys
  keys = {}
  if details.keys
    for key, value of details.keys
      keys[key] = getDef(value)

  # Creating definition
  return definitions[name] = (obj) ->

    console.log 'checking type of obj'
    return false unless check obj, type

    console.log 'checking inheritance'
    if inherit then return false unless inherit(obj)

    console.log 'checking keys'
    for key, value of obj
      console.log key, value
      if prop
        console.log 'checking prop', value
        return false unless prop(value)
      else if keys
        console.log 'checking for definition', key
        return false unless keys[key]
        console.log 'testing key', key
        return false unless keys[key](value)

    console.log 'passed'

    return true

defineFn = (name, args...) ->
  return (input) ->
    for arg, i in input
      return false unless check arg, args[i]
    return true


# -----------------------------------------------------------------------------
# Useful definitions
# -----------------------------------------------------------------------------

define 'array', 'object', Array.isArray

module.exports =
  define: define
  defineFn: defineFn
