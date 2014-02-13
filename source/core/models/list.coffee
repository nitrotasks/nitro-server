db = require '../controllers/database'


class UserLists

  constructor: (@userId) ->

  create: (list) ->
    list.userId = @userId
    List.create(list)

  get: (id) ->
    new List(id)

  owns: (id) ->
    db.list.exists(id: id, userId: @userId)

  all: ->
    db.list.search('*', userId: @userId).map (list) =>
      @get(list.id).tasks()
      .then (tasks) -> list.tasks = tasks
      .return(list)
    .catch -> return []

  destroyAll: ->
    db.list.destroy(userId: @userId)


class List

  @create: (list) ->
    db.list.create
      userId: list.userId
      name:   list.name

  constructor: (@id) ->

  read: (columns) ->
    db.list.read(@id, columns)

  update: (changes) ->
    db.list.update(@id, changes)

  destroy: ->
    db.list.destroy(@id, true)

  tasks: ->
    db.list_tasks.read(@id)

module.exports = UserLists
