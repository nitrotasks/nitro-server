# Hold all the definitions
definitions = {}

# Get a definition
getDef = (name) ->
  def = definitions[name]
  if not def then return checkType(name)
  return def.fn

# Check an object is of a native type
check = (obj, type) ->
  return typeof obj is type

# Curried version of `check`
checkType = (type) ->
  return (obj) -> return typeof obj is type

# Create a new type definition
define = (name, type, details) ->

  def = definitions[name]

  if def then throw new Error('Definition already defined: ' + name)

  # Create definition
  def.name = name
  def.type = type
  def.details = details

  # Get function to check type of object
  typeCheck = getDef(type)

  # Simplest definition
  if not details
    def.fn = getDef(type)
    return def

  # Checking function
  if check details, 'function'
    def.fn = details
    return def

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
    return false unless typeCheck obj

    if inherit then return false unless inherit(obj)

    for key, value of obj
      if prop
        return false unless prop(value)
      else if keys
        return false unless keys[key]
        return false unless keys[key](value)

    return true

defineFn = (name, args...) ->
  return (input) ->
    for arg, i in input
      return false unless check arg, args[i]
    return true


# -----------------------------------------------------------------------------
# Useful Definitions
# -----------------------------------------------------------------------------

# Preserve the native object type
define '*object', 'object'

# Add array type
define 'array', 'object', Array.isArray

# Override the native object type to exclude arrays
define 'object', 'object', (obj) -> not Array.isArray(obj)


# -----------------------------------------------------------------------------
# Exports
# -----------------------------------------------------------------------------

module.exports =
  define: define
  defineFn: defineFn
