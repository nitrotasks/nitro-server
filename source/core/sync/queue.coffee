Promise = require('bluebird')
Time    = require('../models/time')

CREATE = 0
UPDATE = 1
DESTROY = 2

merge = (sync, queue, clientTime) ->

  offset = Time.now() - clientTime

  mergePref(sync, queue, offset)
  .then ->
    mergeList(sync, queue, offset)
  .then (lists) ->
    mergeTask(sync, lists, queue, offset)
  .then ->
    exportUser(sync.user)
  .catch (err) ->
    console.log err
    return null

mergePref = (sync, queue, offset) ->

  promises = for [event, pref, time] in queue
    time = Time.offset(offset, time)
    continue unless event is UPDATE
    sync.pref_update(pref, null, time)

  return Promise.all(promises)

mergeList = (sync, queue, offset) ->

  promises = for [event, list, time] in queue

    time = Time.offset(offset, time)

    switch event

      when CREATE
        tasks = list.tasks
        for taskId, i in tasks by -1 when taskId < 0
          tasks.splice(i, 1)

        do ->
          id = list.id
          sync.list_create(list, null, time).then (_id) ->
            lists[id] = _id

      when UPDATE
        sync.list_update(list, null, time)

      when DESTROY
        sync.list_destroy(list, null, time)

  return Promise.all(promises)

mergeTask = (sync, lists, queue, offset) ->

  promises = for [event, task, time] in queue
    time = Time.offset(offset, time)

    if lists[task.listId]
      task.listId = lists[task.listId]

    switch event

      when CREATE
        sync.task_create(task, null, time)

      when UPDATE
        push sync.task_update(task, null, time)

      when DESTROY
        push sync.task_destroy(task, null, time)

  return Promise.all(promises)

exportUser =  (user) ->

  Promise.all [
    user.list.all()
    user.task.all()
    user.pref.read()
  ]
  .spread (list, task, pref) ->
    { list, task, pref }

module.exports = merge
