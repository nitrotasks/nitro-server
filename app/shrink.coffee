###

     __        __                     __  
    /__` |__| |__) | |\ | |__/     | /__` 
    .__/ |  | |  \ | | \| |  \ .\__/ .__/ 

    -------------------------------------

    Compacts an object by replacing the
    property names with letters.
    And then packing it into a buffer
    using msgpack.

    Customise the `tableTo` object.
    
    It exposes two methods:
      - pack
      - unpack

    If you don't want to compress using
    MsgPack, then pass true as the second
    argument.

###

# Use MsgPack to compress data
msgpack   = require 'msgpack'

# Lookup table for compressing data
tableTo =

  # Class names
  Task: "T"
  List: "L"
  Time: "M"
  Setting: "S"

  # Properties
  name:      "n"
  completed: "c"
  id:        "i"
  priority:  "p"
  date:      "d"
  deleted:   "x"
  notes:     "o"
  tasks:     "t"
  list:      "l"
  permanent: "q"
  inbox:     "b"

# Generate tableFrom object by inverting tableTo
tableFrom = {}
for k, v of tableTo
  tableFrom[v] = k

# Get a value from the table
# If value doesn't exist, then use the current value
get = (name, table) ->
  table[name] or name

# Replace an obj with values from the table
replace = (obj, table) ->
  out = {}
  for key, value of obj
    if typeof value is "object" and not Array.isArray(value)
      for cKey, cValue of value
        out[get(key, table)] = replace(value, table)
    else
      out[get(key, table)] = value
  return out

# Make sure object is an object
makeObj = (obj) ->
  if typeof obj is "string"
    try obj = JSON.parse obj
    catch e then return {}
  return obj

Shrink =
  pack: (obj, asJSON) ->
    data = replace(makeObj(obj), tableTo)
    if asJSON then return data
    msgpack.pack(data)

  unpack: (obj, asJSON) ->
    if not asJSON then obj = msgpack.unpack(obj)
    replace(makeObj(obj), tableFrom)

module?.exports = Shrink
