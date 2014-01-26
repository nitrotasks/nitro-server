Q = require 'kew'
db = require '../controllers/query'


class User

  ###
   * Create a new User instance
   *
   * - [attrs] (object) : optional attributes to load in
   * - [duration] (int) : how long to wait between writes
  ###

  constructor: (@id) ->


  # Resolve cyclic dependency with Storage controller
  module.exports = User
  Storage = require '../controllers/storage'

  info: ->
    db.user.read @id, ['name', 'email', 'password']

  ###
   * Get Inbox
  ###

  getInbox: ->
    db.user.read @id, 'inbox'

  setInbox: (id) ->
    db.user.update(@id, inbox: id).then ->
      return id



  ###
   * Set Name
  ###

  setName: (name) ->
    db.user.update @id, name: name

  getName: ->
    db.user.read(@id, 'name').then (info) ->
      return info.name

  ###
   * Change a users password and remove all their login tokens
   *
   * - password (string) : the hash of the password
  ###

  setPassword: (password) ->
    db.login.destroyAll @id
    db.user.update @id, password: password

  getPassword: ->
    db.user.read(@id, 'password').then (info) ->
      return info.password


  ###
   * Change a users email and update the email lookup table
   *
   * - email (string) : the email to change to
  ###

  setEmail: (email) ->
    db.update @id, email: email

  getEmail: ->
    db.user.read(@id, 'email').then (info) ->
      return info.email


  createModel: (classname, properties) ->
    db[classname].create(properties)

  createList: (list) ->
    @createModel 'list',
      userId: @id
      name: list.name

  createTask: (task) ->
    @createModel 'task',
      userId: @id
      listId: task.listId
      name: task.name
      notes: task.notes
      date: task.date
      priority: task.priority
      completed: task.completed

  createPref: (pref) ->
    @createModel 'pref',
      userId: @id
      sort: pref.sort
      night: pref.night
      language: pref.language
      weekStart: pref.weekStart
      dateFormat: pref.dateFormat
      confirmDelete: pref.confirmDelete
      moveCompleted: pref.moveCompleted


  addTaskToList: (taskId, listId) ->
    db.listTasks.create(listId, taskId)

  removeTaskFromList: (taskId, listId) ->
    db.listTasks.destroy(listId, taskId)

  readListTasks: (listId) ->
    db.listTasks.read(listId)


  shouldOwnModel: (classname, id) ->
    db[classname]._search 'id',
      id: id
      userId: @id

  shouldOwnTask: (id) ->
    @shouldOwnModel('task', id)

  shouldOwnList: (id) ->
    @shouldOwnModel('list', id)


  checkModel: (classname, id) ->
    db[classname].exists(id)

  checkList: (id) ->
    @checkModel('list', id)

  checkTask: (id) ->
    @checkModel('task', id)

  checkPref: (id) ->
    @checkModel('pref', id)


  readModel: (classname, id, columns) ->
    db[classname].read(id, columns).then (obj) ->
      delete obj.userId
      return obj

  readList: (id, columns) ->
    @readModel('list', id, columns)

  readTask: (id, columns) ->
    @readModel('task', id, columns)

  readPref: (columns) ->
    @readModel('pref', @id, columns)


  updateModel: (classname, id, changes) ->
    db[classname].update(id, changes)

  updateList: (id, changes) ->
    @updateModel('list', id, changes)

  updateTask: (id, changes) ->

    # Check listId
    if changes.listId?
      @shouldOwnList(changes.listId)
        .then =>
          @readTask(id, 'listId')
        .then (old) =>
          return if old.listId is changes.listId
          @removeTaskFromList id, old.listId
        .then =>
          @addTaskToList id, changes.listId
        .fail ->
          delete changes.listId
        .then =>
          @updateModel('task', id, changes)
    else
      @updateModel('task', id, changes)

  updatePref: (changes) ->
    @updateModel('pref', @id, changes)


  destroyModel: (classname, id) ->
    db[classname].destroy(id)

  destroyList: (id) ->
    @destroyModel('list', id)

  destroyTask: (id) ->
    @destroyModel('task', id)

  destroyPref: ->
    @destroyModel('pref', @id)


  ###
   * Get an array of all the active models in a class
   *
   * - classname (string)
   * > object
  ###

  exportModel: (classname) ->
    models = []
    data = @data classname
    return models unless data
    for id, model of data when not model.deleted
      models.push model
    return models


  exportTasks: ->
    db.task._search('*', userId: @id).then (tasks) ->
      for task in tasks
        delete task.userId
      return tasks

  exportLists: ->
    db.list._search('*', userId: @id)
      .then (lists) ->
        promises = []
        lists.forEach (list) ->
          delete list.userId
          promises.push db.listTasks.read(list.id).then (tasks) ->
            list.tasks = tasks
        Q.all(promises).then -> return lists

  exportPref: ->
    db.pref.read(@id, '*')