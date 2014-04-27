Promise = require('bluebird')
Time    = require('../models/time')


###
 * Constants
###

CREATE = 0
UPDATE = 1
DESTROY = 2


###
 * Queue
###

class Queue

  constructor: (@queue, clientTime) ->
    @offset = Time.now() - clientTime
    @queue.list ?= []
    @queue.task ?= []
    @queue.pref ?= []

  run: ->
    @mergePrefs()
    .bind(this)
    .then(@mergeLists)
    .then(@mergeTasks)


  mergePrefs: ->
    # TODO: replace with map
    promises = for [event, pref, time] in @queue.pref
      time = Time.offset(@offset, time)
      unless event is UPDATE then continue
      @sync.pref_update(pref, null, time)
    return Promise.all(promises)


  mergeLists: ->

    # Store server list ids
    lists = {}

    promises = for [event, list, time] in queue.list

      time = Time.offset(@offset, time)

      switch event

        when CREATE
          tasks = list.tasks

          # TODO: Update client taskIds instead of removing them
          for taskId, i in tasks by -1 when taskId < 0
            tasks.splice(i, 1)

          do =>
            id = list.id
            @sync.list_create(list, null, time)
              .then (list) -> lists[id] = list.id

        when UPDATE
          @sync.list_update(list, null, time)

        when DESTROY
          @sync.list_destroy(list, null, time)

    return Promise.all(promises).return(lists)



  mergeTasks: (lists) ->

    promises = for [event, task, time] in queue.task

      time = Time.offset(@offset, time)

      # Replace client listId with server listId
      if lists[task.listId]
        task.listId = lists[task.listId]

      switch event

        when CREATE
          @sync.task_create(task, null, time)

        when UPDATE
          @sync.task_update(task, null, time)

        when DESTROY
          @sync.task_destroy(task, null, time)

    return Promise.all(promises)



class SyncQueue

  constructor: (@sync) ->

  merge: (queue, clientTime) ->

    queue = new Queue(queue, clientTime)
    queue.run()
    .then -> @export()

  export:  ->

    Promise.all [
      @sync.user.list.all()
      @sync.user.task.all()
      @sync.user.pref.read()
    ]
    .spread (list, task, pref) ->
      { list, task, pref }



module.exports = SyncQueue
