{define, defineFn} = require 'xtype'

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
    completed: 'number'

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

define 'Timestamps', 'object',
  all: 'number'


define 'CreateEvent', 'array',
  keys:
    2: 'number'

define 'UpdateEvent', 'array',
  keys:
    2: 'Timestamps'

define 'DestroyEvent', 'array',
  keys:
    2: 'number'


define 'QueueEvent', 'array',
  inherit: ['CreateEvent', 'UpdateEvent', 'DestroyEvent']
  check: (arr) -> arr[0]


define 'TaskEvent', 'array',
  inherit: 'QueueEvent'
  keys:
    0: 'number'
    1: 'Task'

define 'ListEvent', 'array',
  inherit: 'QueueEvent'
  keys:
    0: 'number'
    1: 'List'

define 'PrefEvent', 'array',
  inherit: 'QueueEvent'
  keys:
    0: 'number'
    1: 'Pref'



define 'TaskQueue', 'object',
  all: 'TaskEvent'

define 'ListQueue', 'object',
  all: 'ListEvent'

define 'PrefQueue', 'object',
  all: 'PrefEvent'



define 'Queue', 'object',
  keys:
    task: 'TaskQueue'
    list: 'ListQueue'
    pref: 'PrefQueue'


# ----------------------------------------------------------------------------
# Sockets
# ----------------------------------------------------------------------------

defineFn 'user_auth', 'number', 'string', 'function'
defineFn 'user_info', 'function'

defineFn 'task_fetch', 'function'
defineFn 'list_fetch', 'function'
defineFn 'pref_fetch', 'function'

defineFn 'task_create', 'Task', 'number', 'function'
defineFn 'list_create', 'List', 'number', 'function'

defineFn 'task_update', 'Task', 'Timestamps', '~function'
defineFn 'list_update', 'List', 'Timestamps', '~function'
defineFn 'pref_update', 'Pref', 'Timestamps', '~function'

defineFn 'task_destroy', 'Task', 'number', '~function'
defineFn 'list_destroy', 'List', 'number', '~function'

defineFn 'queue_sync', 'Queue', 'function'
