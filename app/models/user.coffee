Promise = require 'bluebird'
db = require '../controllers/query'
time = require '../utils/time'
Log = require '../utils/log'

log = Log('user', 'green')

ERR_NO_ROW = 'err_no_row'

class User

  ###
   * Create a new User instance
   *
   * - [attrs] (object) : optional attributes to load in
   * - [duration] (int) : how long to wait between writes
  ###

  constructor: (@id) ->

  setup: ->
    db.pref.create(userId: @id)
    .then =>
      time.create('pref', @id, {})
    .then =>
      return this

  info: ->
    db.user.read @id, ['name', 'email', 'pro']


  ###
   * Set Name
   *
   * - name (string) : the users name
  ###

  setName: (name) ->
    db.user.update @id, name: name

  getName: ->
    db.user.read(@id, 'name').then (info) ->
      return info.name


  ###
   * Change a users email and update the email lookup table
   *
   * - email (string) : the email to change to
  ###

  setEmail: (email) ->
    db.user.update @id, email: email

  getEmail: ->
    db.user.read(@id, 'email').then (info) ->
      return info.email


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
    db.list_tasks.create(listId, taskId)

  removeTaskFromList: (taskId, listId) ->
    db.list_tasks.destroy(listId, taskId)

  readListTasks: (listId) ->
    db.list_tasks.read(listId)


  shouldOwnModel: (classname, id) ->
    db[classname]._search 'id',
      id: id
      userId: @id

  shouldOwnTask: (id) ->
    @shouldOwnModel('task', id).catch ->
      log '[task] does not own', id
      throw 'err_no_row'

  shouldOwnList: (id) ->
    @shouldOwnModel('list', id).catch ->
      log '[list] does not own', id
      throw 'err_no_row'


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
    @updateModel('task', id, changes)

  updatePref: (changes) ->
    @updateModel('pref', @id, changes)


  destroyModel: (classname, id) ->
    db[classname].destroy(id).then (success) ->
      if not success then throw ERR_NO_ROW
      return success

  destroyList: (id) ->
    @destroyModel('list', id)

  destroyTask: (id) ->
    @destroyModel('task', id)

  destroyPref: ->
    @destroyModel('pref', @id)


  clearAllData: ->
    db.task._delete(userId: @id)
    .then =>
      db.list._delete(userId: @id)
    .then =>
      db.pref._delete(userId: @id)
    .then =>
      @setup()


  ###
   * Get an array of all the active models in a class
   *
   * - classname (string)
   * > object
  ###

  exportTasks: ->
    db.task._search('*', userId: @id)
    .then (tasks) ->
      for task in tasks
        delete task.userId
      return tasks
    .catch ->
      return []

  exportLists: ->
    db.list._search('*', userId: @id)
    .then (lists) =>
      promises = []
      lists.forEach (list) =>
        delete list.userId
        promises.push @readListTasks(list.id).then (tasks) ->
          list.tasks = tasks
      Promise.all(promises).then -> return lists
    .catch ->
      return []

  exportPref: ->
    @readPref()


module.exports = User