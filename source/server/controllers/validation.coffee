{define, defineFn} = require 'xtype'

# ----------------------------------------------------------------------------
# Flexible Models
# ----------------------------------------------------------------------------

define 'Task', 'object',
  keys:
    id: 'number'
    listId: 'number'
    date: 'number'
    name: 'string'
    notes: 'string'
    priority: 'number'
    completed: 'number'

define 'TaskCollection', 'array',
  all: 'number'

define 'List', 'object',
  keys:
    id: 'number'
    name: 'string'
    tasks: 'TaskCollection'

define 'Pref', 'object',
  keys:
    sort: 'number'
    night: 'number'
    language: 'string'
    weekStart: 'number'
    dateFormat: 'string'
    confirmDelete: 'number'
    moveCompleted: 'number'



# -----------------------------------------------------------------------------
# Strict Models
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


define 'TaskCreateEvent', 'array',
  inherit: 'CreateEvent'
  keys:
    1: 'CreateTask'

define 'TaskUpdateEvent', 'array',
  inherit: 'UpdateEvent'
  keys:
    1: 'UpdateTask'

define 'TaskDestroyEvent', 'array',
  inherit: 'DestroyEvent'
  keys:
    1: 'DestroyTask'


define 'ListCreateEvent', 'array',
  inherit: 'CreateEvent'
  keys:
    1: 'CreateList'

define 'ListUpdateEvent', 'array',
  inherit: 'UpdateEvent'
  keys:
    1: 'UpdateList'

define 'ListDestroyEvent', 'array',
  inherit: 'DestroyEvent'
  keys:
    1: 'DestroyList'


define 'TaskQueueEvent', 'array',
  inherit: ['TaskCreateEvent', 'TaskUpdateEvent', 'TaskDestroyEvent']
  check: (arr) -> arr[0]

define 'ListQueueEvent', 'array',
  inherit: ['ListCreateEvent', 'ListUpdateEvent', 'ListDestroyEvent']
  check: (arr) -> arr[0]


define 'TaskEvent', 'array',
  inherit: 'TaskQueueEvent'
  keys: 0: 'number'
  required: [0,1,2]

define 'ListEvent', 'array',
  inherit: 'ListQueueEvent'
  keys: 0: 'number'
  required: [0,1,2]

define 'PrefEvent', 'array',
  keys:
    0: 'number'
    1: 'Pref'
    2: 'Timestamps'
  required: [0,1,2]


define 'TaskQueue', 'array',
  all: 'TaskEvent'

define 'ListQueue', 'array',
  all: 'ListEvent'

define 'PrefQueue', 'array',
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

defineFn 'queue_sync', 'Queue', 'number', 'function'
