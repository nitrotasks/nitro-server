Promise = require('bluebird')
offset  = require('../models/time').offset

CREATE = 0
UPDATE = 1
DESTROY = 2

merge = (sync, queue, clientTime) ->

  pAll = [] # stores all the promises
  pList = [] # stores just the list promises

  offset = time.now() - clientTime

  mergePref(sync, queue, offset)
  .then ->
    mergeList(sync, queue, offset)
  .then (lists) ->
    mergeTask(sync, lists, queue, offset)
  .then ->
    exportUser(sync.user)
  .catch (err) ->
    return null

mergePref = (sync, queue, offset) ->

  promises = []

  for [event, pref, time] in queue
    offset(offset, time)
    continue unless event is UPDATE
    promises.push sync.pref_update(pref, null, time)

  return promises

mergeList = (sync, queue, offset) ->

  for [event, list, time] in queue

    offset(offset, time)

    switch event

      when CREATE
        tasks = list.tasks
        for taskId, i in tasks by -1 when taskId < 0
          tasks.splice(i, 1)

        do ->
          id = list.id
          promises.push sync.list_create(list, null, time).then (_id) ->
            lists[id] = _id

      when UPDATE
        pAll.push sync.list_update(list, null, time)

      when DESTROY
        pAll.push sync.list_destroy(list, null, time)

mergeTask = (sync, lists, queue, offset) ->

  for [event, task, time] in queue
    offset(offset, time)

    if lists[task.listId]
      task.listId = lists[task.listId]

    switch event

      when CREATE
        pAll.push sync.task_create(task, null, time)

      when UPDATE
        pAll.push sync.task_update(task, null, time)

      when DESTROY
        pAll.push sync.task_destroy(task, null, time)

  return pAll

exportUser =  (user) ->

  Promise.all [
    user.lists.all()
    user.tasks.all()
    user.pref.read()
  ]
  .spread(lists, tasks, pref) -> { lists, tasks, pref }

module.exports = merge
