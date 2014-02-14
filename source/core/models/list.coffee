db = require '../controllers/database'


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


class UserLists

  @List: List

  constructor: (@userId) ->

  create: (list) ->
    list.userId = @userId
    List.create(list)

  get: (id) ->
    new List(id)

  owns: (id) ->
    db.list.search('id', { id: id, userId: @userId }).return(true)

  all: ->
    db.list.search('*', userId: @userId).map (list) =>
      @get(list.id).tasks()
      .then (tasks) -> list.tasks = tasks
      .return(list)
    .catch -> []

  destroy: ->
    db.list.destroy(userId: @userId)


module.exports = UserLists
