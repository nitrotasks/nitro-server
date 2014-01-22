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

define 'TaskCollection', 'array',
  all: 'string'

define 'List', 'object',
  keys:
    id: 'string'
    name: 'string'
    tasks: 'TaskCollection'

define 'Pref', 'object',
  keys:
    sort: 'boolean'
    night: 'string'
    language: 'string'
    weekStart: 'number'
    dateFormat: 'string'
    confirmDelete: 'boolean'
    completedDuration: 'string'



# -----------------------------------------------------------------------------
# Strict Tasks
# -----------------------------------------------------------------------------

define 'CreateList', 'object',
  required: ['id', 'name', 'tasks']
  inherit: 'List'

define 'UpdateList', 'object',
  required: ['id']
  inherit: 'List'

define 'DestroyList', 'object',
  required: ['id']
  inherit: 'List'

define 'CreateTask', 'object',
  required: ['id', 'listId', 'date', 'name', 'notes', 'priority', 'completed']
  inherit: 'Task'

define 'UpdateTask', 'object',
  required: ['id']
  inherit: 'Task'

define 'DestroyTask', 'object',
  required: ['id']
  inherit: 'Task'


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
  required: [0,1,2]

define 'ListEvent', 'array',
  inherit: 'QueueEvent'
  keys:
    0: 'number'
    1: 'List'
  required: [0,1,2]

define 'PrefEvent', 'array',
  inherit: 'QueueEvent'
  keys:
    0: 'number'
    1: 'Pref'
  required: [0,1,2]


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

defineFn 'task_create', 'CreateTask', 'function'
defineFn 'list_create', 'CreateList', 'function'

defineFn 'task_update', 'UpdateTask', '~function'
defineFn 'list_update', 'UpdateList', '~function'
defineFn 'pref_update', 'Pref', '~function'

defineFn 'task_destroy', 'DestroyTask', '~function'
defineFn 'list_destroy', 'DestroyList', '~function'

defineFn 'queue_sync', 'Queue', 'function'
