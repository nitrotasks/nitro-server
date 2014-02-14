db    = require('../controllers/database')
Time  = require('../models/time')
Prefs = require('../models/pref')
Lists = require('../models/list')
Tasks = require('../models/task')


# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

ERR_OLD_EMAIL = 'err_old_email'


# -----------------------------------------------------------------------------
# User Class
# -----------------------------------------------------------------------------

class User

  @create: (user) ->
    db.user.create
      name: user.name
      email: user.email
      password: user.password
      pro: user.pro

  ###
   * Create a new User instance
   *
   * - [attrs] (object) : optional attributes to load in
   * - [duration] (int) : how long to wait between writes
  ###

  constructor: (@id) ->
    @prefs = new Prefs(@id)
    @tasks = new Tasks(@id)
    @lists = new Lists(@id)

  setup: ->
    @prefs.create()
    .then => Time.create('pref', @id, {})
    .return(this)

  read: (columns) ->
    db.user.read(@id, columns)

  update: (changes) ->
    db.user.update(@id, changes)

  destroy: ->
    db.user.destroy(@id, true).return(true)



# -----------------------------------------------------------------------------
# Users Controller
# -----------------------------------------------------------------------------

Users =

  User: User

  ###
   * Users.create
   *
   * This will add a user to the database
   * It will then return a new instance of the user
   *
   * - user (object) : { name, email, password }
   * > User
  ###

  # Add user to database and return user as instance
  create: (user) ->
    Users.emailExists(user.email)
    .then (exists) ->
      if exists then throw new Error(ERR_OLD_EMAIL)
      User.create(user)
    .then (id) ->
      user = new User(id)
      user.setup()


  ###
   * Users.read
   *
   * This will retrive a user from the database by their ID.
   * Will return the user as a User instance.
   * Will throw an error if the user can't be found.
   *
   * - id (int) : The id of the user to get
   * > User
   * ! err_no_row
  ###

  get: (id) ->
    Users.exists(id).then -> new User(id)


  ###
   * Users.search
   *
   * Get a user by their email address
   *
   * - email (string)
   * > user
   * ! err_no_row
  ###

  search: (email) ->
    db.user.search('id', { email })
    .then (rows) -> new User(rows[0].id)


  ###
   * Users.exists
   *
   * Check if an email address has been used
   *
   * - email (string)
   * > boolean
  ###

  emailExists: (email) ->
    db.user.exists({ email })

  exists: (id) ->
    db.user.search('id', { id }).return(true)



  ###
   * Users.destroyAll
   *
   * Use with absolute caution.
   * Only works in debug mode.
  ###

  destroyAll: ->

    if not DEBUG then throw new Error('You nearly deleted all the users data!')
    db.user.destroy({})


module.exports = Users
