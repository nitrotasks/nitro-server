Q    = require 'kew'
db   = require '../controllers/query'
Log  = require '../utils/log'
User = require '../models/user'

log = Log 'Storage', 'green'


# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

ERR_OLD_EMAIL = 'err_old_email'
ERR_BAD_TOKEN = 'err_bad_token'
ERR_NO_USER   = 'err_no_user'


# -----------------------------------------------------------------------------
# Storage Controller
# -----------------------------------------------------------------------------

Storage =

  ###
   * This will store user data in a temporary key until
   * they have verified their account.
   * The email used must not exist in the database.
   *
   * - token (string) : special id assigned to the data
   * - user (object) : { name, email, password }
   * > token
   * ! err_old_email
  ###

  register: (token, name, email, password) ->
    @emailExists(email).then (exists) ->
      if exists then throw ERR_OLD_EMAIL
      db.register.create
        token: token
        name: name
        email: email
        password: password
      # redis.expire key, 172800 # 48 hours
      # return token


  ###
   * This will check if registration token exists.
   * If the token can't be found an error will be thrown.
   * If it is found then the registration will be deleted
   * and the user data returned.
   *
   * - token (string) : the registration token
   * > return user data
   * ! err_bad_token
  ###

  getRegistration: (token) ->
    db.register.read(token)
      .then (data) ->
        db.register.destroy(data.id)
        return data
      .fail ->
        throw ERR_BAD_TOKEN


  ###
   * This will add a user to the database
   * It will then return a new instance of the user
   *
   * - user (object) : { name, email, password }
   * > User
  ###

  # Add user to database and return user as instance
  add: (user) ->
    @emailExists(user.email).then (exists) =>
      if exists then throw ERR_OLD_EMAIL

      user.pro = 0
      id = null

      # Add user to database
      db.user.create(user)
      .then (id) =>
        @get id
      .then (user) ->
        user.setup()


  ###
   * This will retrive a user from the database by their ID.
   * If the user is already loaded in memory, it will return that instance,
   * Else it will load it from the database and add it to the records.
   * Will return the user as a User instance.
   * Will throw an error if the user can't be found.
   *
   * - id (int) : The id of the user to get
   * > User
   * ! err_no_user
  ###

  get: (id) ->
    db.user.read(id, 'id').then ->
      return new User(id)

  ###
   * Get a user by their email address
   *
   * - email (string)
   * > user
  ###

  getByEmail: (email) ->
    db.user.search(email)
      .then @get, -> throw ERR_NO_USER

  ###
   * Check if an email address exists in the system
   *
   * - email (string)
   * > boolean
  ###

  emailExists: (email) ->
    db.user.search(email)
      .then ->
        return true
      .fail ->
        return false

  ###
   * Completely remove a user from the system
   * We could integrate it with @release(id), but that would write
   * it to the database, right before we instantly delete it.
   *
   * - id (int) : the user id
  ###

  destroy: (id) ->
    log "Removing user #{ id }"
    db.user.destroy id


  ###
   * Add a new login token.
   * It will expire after two weeks.
   *
   * - id (int) : the user id
   * - token (string) : the login token
   * > token
  ###

  addLoginToken: (id, token) ->
    db.login.create(id, token).then ->
      return token


  ###
   * Check that a login token is valid
   *
   * - id (int) : the user id
   * - token (string) : the login token
   * > boolean
  ###

  checkLoginToken: (id, token) ->
    db.login.exists(id, token)


  ###
   * Remove a specific login token
   *
   * - id (int) : the user id
   * - token (string) : the login token
  ###

  destroyLoginToken: (id, token) ->
    db.login.destroy(id, token)


  ###
   * Remove all the login tokens for a user
   *
   * - id (int) : the user id
  ###

  destroyAllLoginTokens: (id) ->
    db.login.destroyAll(id)


  ###
   * Add a new password reset token
   * Tokens are removed after 12 hours
   *
   * - id (int) : the user id
   * - token (string) : the reset token
   * > database reset token
  ###

  addResetToken: (id, token) ->
    db.reset.create(id, token)
    # redis.setex(key, 86400, id).then ->


  ###
   * Check that a reset token is valid
   *
   * - token (string) : the reset token
   * > int : the user id
  ###

  checkResetToken: (token) ->
    db.reset.read(token).fail ->
      throw ERR_BAD_TOKEN

  ###
   * Destroy a reset token
   *
   * - token (string) : the reset token
  ###

  destroyResetToken: (token) ->
    db.reset.destroy(token)

module.exports = Storage
