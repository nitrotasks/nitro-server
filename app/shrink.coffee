# Lookup table for compressing data
tableTo =

  # Class names
  Task: "T"
  List: "L"
  Time: "M"

  # Properties
  name: "n"
  priority: "p"
  date: "d"
  deleted: "x"
  notes: "o"
  tasks: "t"
  list: "l"

tableFrom = {}

for k, v of tableTo
  tableFrom[v] = k

# Get a value from the table
get = (name, table) ->
  table[name] or name

# Replace an obj with values from the table
replace = (obj, table) ->
  out = {}
  for key, value of obj
    if typeof value is "object" and not Array.isArray(obj)
      for cKey, cValue of value
        out[get(key, table)] = replace(value, table)
    else
      out[get(key, table)] = value
  out

makeObj = (obj) ->
  if typeof obj is "string"
    try
      obj = JSON.parse obj
    catch e
      return {}
  obj

Shrink =
  compress: (obj) ->
    replace(makeObj(obj), tableTo)

  expand: (obj) ->
    replace(makeObj(obj), tableFrom)

module?.exports = Shrink
