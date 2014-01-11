definitions = {}

getDef = (name) ->
  def = definitons[nmea]
  if not def then throw new Error 'Could not find', name
  return def

checkType = (obj, type) ->
  return typeof obj is type

define = (name, type, details) ->
  if definitions[name]
    throw new Error('Definition already defined: ' + name)

  if not details
    fn = (obj) -> checkType(obj, type)

  inherit = details.inherit
  if typeof inherit is 'function'
    inherit = (obj) ->
      return definitions[details.inherit(obj)](obj)
  else if typeof inherit is 'string'
    inherit = definitions[inherit]

  keys = {}
  if details.keys
    for key, type of details.keys
      keys[key] = getDef(type)

  definitions[name] = (obj) ->
    return false unless checkType obj, type

    if inherit then return false unless inherit(obj)

    return true

defineFn = (name, args...) ->
  return (input) ->
    for arg, i in input
      return false unless checkType arg, args[i]
    return true


# ----------------------------------------------------------------------------
# Native
# ----------------------------------------------------------------------------

define 'function', 'function'
define 'string', 'string'
define 'number', 'number'
define 'boolean', 'boolean'

define 'bool', 'boolean'
define 'int', 'number'
define 'fn', 'function'


# ----------------------------------------------------------------------------
# Models
# ----------------------------------------------------------------------------

define 'Task', 'object',
  keys:
    id: 'string'
    listId: 'string'
    date: 'number'
    name: 'string'
    notes: 'string'
    priority: 'number'
    completed: 'boolean'

define 'List', 'object',
  keys:
    id: 'string'
    name: 'string'
    tasks: 'array'

define 'Pref', 'object',
  keys:
    id: 'string'
    sort: 'boolean'
    night: 'string'
    language: 'string'
    weekstart: 'number'
    dateFormat: 'string'
    confirmDelete: 'boolean'
    completedDuration: 'string'


# ----------------------------------------------------------------------------
# Queue
# ----------------------------------------------------------------------------

define 'Queue', 'object',
  keys:
    task: 'TaskQueue'
    list: 'ListQueue'
    pref: 'PrefQueue'

define 'TaskQueue', 'object',
  keys:
    '*': 'TaskEvent'

define 'ListQueue', 'object',
  keys:
    '*': 'ListEvent'

define 'PrefQueue', 'object',
  keys:
    '*': 'PrefEvent'

define 'QueueEvent', 'array',
  keys:
    0: 'number'
  inherit: (arr) ->
    switch arr[0]
      when 0
        return 'CreateEvent'
      when 1
        return 'UpdateEvent'
      when 2
        return 'DestroyEvent'

define 'CreateEvent', 'array',
  keys:
    2: 'number'

define 'UpdateEvent', 'array',
  keys:
    2: 'Timestamps'

define 'DestroyEvent', 'array',
  keys:
    2: 'number'
  inherit: 'QueueEvent'

define 'TaskEvent', 'array',
  keys:
    1: 'Task'
  inherit: 'QueueEvent'

define 'ListEvent', 'array',
  keys:
    1: 'List'

define 'Pref', 'array',
  keys:
    1: 'Pref'
  inherit: 'QueueEvent'

define 'Timestamps', 'object',
  keys:
    '*': 'number'


# ----------------------------------------------------------------------------
# Sockets
# ----------------------------------------------------------------------------

defineFn 'user_auth', 'number', 'string', 'function'
defineFn 'user_info', 'function'

defineFn 'task_fetch', 'function'
defineFn 'list_fetch', 'function'
defineFn 'pref_fetch', 'function'

defineFn 'task_create', 'Task', 'function'
defineFn 'list_create', 'List', 'function'

defineFn 'task_update', 'Task', 'Timestamps', '~function'
defineFn 'list_update', 'List', 'Timestamps', '~function'
defineFn 'pref_update', 'Pref', 'Timestamps', '~function'

defineFn 'task_destroy', 'Task', 'string', '~function'
defineFn 'list_destroy', 'List', 'string', '~function'

defineFn 'model_sync', 'Queue', 'function'
