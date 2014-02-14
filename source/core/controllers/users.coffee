db      = require '../controllers/query'
Log     = require '../utils/log'
User    = require '../models/user'

log = Log 'Users', 'green'


# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

ERR_OLD_EMAIL = 'err_old_email'
ERR_NO_USER   = 'err_no_user'


# -----------------------------------------------------------------------------
# Users Controller
# -----------------------------------------------------------------------------

Users =

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
    Users.exists(user.email)
    .then (exists) ->
      if exists then throw ERR_OLD_EMAIL
      db.user.create(user)
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
   * ! err_no_user
  ###

  read: (id) ->
    db.user.exists(id).then (exists) ->
      if not exists then throw ERR_NO_USER
      return new User(id)

  ###
   * Users.search
   *
   * Get a user by their email address
   *
   * - email (string)
   * > user
  ###

  search: (email) ->
    db.user.search('id', { email })
      .then(rows) ->
        Users.read(rows[0].id)
      .catch -> throw ERR_NO_USER


  ###
   * Users.exists
   *
   * Check if an email address has been used
   *
   * - email (string)
   * > boolean
  ###

  exists: (email) ->
    db.user.exists(email, 'email')


  ###
   * Users.destroy
   *
   * Completely remove a user from the system
   *
   * - id (int) : the user id
  ###

  destroy: (id) ->
    db.user.destroy(id).return(true)


module.exports = Users
