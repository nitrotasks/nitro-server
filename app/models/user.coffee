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
    db.user.read(@id, ['name', 'email', 'password'])


  ###
   * Set Name
  ###

  setName: (name) ->
    db.user.update @id, name: name


  ###
   * Change a users password and remove all their login tokens
   *
   * - password (string) : the hash of the password
  ###

  setPassword: (password) ->
    db.login.destroyAll @id
    db.user.update @id, password: password


  ###
   * Change a users email and update the email lookup table
   *
   * - email (string) : the email to change to
  ###

  setEmail: (email) ->
    db.update @id, email: email


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

  updateTask: (id, changes) ->
    @updateModel('task', id, changes)

  updateList: (id, changes) ->
    @updateModel('list', id, changes)

  updatePref: (id, changes) ->
    @updateModel('pref', id, changes)


  destroyModel: (classname, id) ->
    db[classname].destroy(id)

  destroyTask: (id) ->
    @destroyModel('task', id)

  destroyList: (id) ->
    @destroyModel('list', id)

  destroyPref: ->
    @destroyModel('pref', @id)


  ###
   * Get a model by an id for a class.
   * If the model doesn't exist, it will be created as an empty object
   *
   * - classname (string)
   * - id (int)
   * > object
  ###

  findModel: (classname, id) =>
    db[classname].read(id, '*')


  ###
   * Check if a model exists
   *
   * - classname (string)
   * - id (int)
   * > boolean
  ###

  hasModel: (classname, id) =>
    db[classname].read(id, 'id')

  ###
   * Check if a model exists and that is not deleted
  ###

  checkModel: (classname, id) =>
    @hasModel(classname, id) and not @data(classname)[id].deleted

  ###
   * Set attributes for a model
   *
   * - classname (string)
   * - id (int)
   * - attributes (object)
   * > object
  ###

  updateModel: (classname, id, attributes) =>
    model = @findModel(classname, id)
    model[key] = value for key, value of attributes
    @save classname
    return model


  ###
   * Replace the attributes for a model
   *
   * - classname (string)
   * - id (int)
   * - attributes (object)
   > attributes
  ###

  setModel: (classname, id, attributes) =>
    @data(classname)[id] = attributes
    @save classname
    return attributes

  ###
   * Get an array of all the active models in a class
   *
   * - classname (string)
   * > object
  ###

  exportModel: (classname) =>
    models = []
    data = @data classname
    return models unless data
    for id, model of data when not model.deleted
      models.push model
    return models
