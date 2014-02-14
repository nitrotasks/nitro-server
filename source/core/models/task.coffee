db = require '../controllers/database'


class Task

  @create: (task) ->
    db.task.create
      userId:    task.userId
      listId:    task.listId
      name:      task.name
      notes:     task.notes
      date:      task.date
      priority:  task.priority
      completed: task.completed

  constructor: (@id) ->

  read: (columns) ->
    db.task.read(@id, columns)

  update: (changes) ->
    db.task.update(@id, changes)

  destroy: ->
    db.task.destroy(@id, true)

  addToList: (listId) ->
    db.list_tasks.create(listId, @id)

  removeFromList: (listId) ->
    db.list_tasks.destroy(listId, @id)


class UserTasks

  @Task: Task

  constructor: (@userId) ->

  create: (task) ->
    task.userId = @userId
    Task.create(task)

  get: (id) ->
    new Task(id)

  owns: (id) ->
    db.task.search('id', { id, @userId }).return(true)

  all: ->
    db.task.search('*', { @userId }).catch -> []

  destroy: ->
    db.task.destroy({ @userId })


module.exports = UserTasks
