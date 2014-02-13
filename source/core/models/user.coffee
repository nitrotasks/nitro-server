Promise = require('bluebird')
dbi     = require('../controllers/database')
time    = require('../utils/time')

class User

  ###
   * Create a new User instance
   *
   * - [attrs] (object) : optional attributes to load in
   * - [duration] (int) : how long to wait between writes
  ###

  constructor: (@id) ->
    @pref = new Pref(@id)
    @tasks = new Tasks(@id)
    @lists = new Lists(@id)


  setup: ->
    @pref.create()
    .then =>
      time.create('pref', @id, {})
    .return(this)


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

module.exports = User