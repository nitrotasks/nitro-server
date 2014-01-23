Q         = require 'kew'
dbase     = require '../controllers/query'
Log       = require '../utils/log'

log = Log 'Storage', 'green'

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

ERR_OLD_EMAIL = 'err_old_email'
ERR_BAD_TOKEN = 'err_bad_token'
ERR_NO_USER   = 'err_no_user'


# -----------------------------------------------------------------------------
# User Factory
# -----------------------------------------------------------------------------

User = null

createUser = (attrs) ->
  User ?= require '../models/user'
  return new User attrs


# -----------------------------------------------------------------------------
# Storage Controller
# -----------------------------------------------------------------------------

Storage =

  ###
   * This object holds all of the user instances
   * that are currently stored in memory.
  ###

  records: {}

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
      dbase.register.add
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
    dbase.register.get(token).then (data) ->
      throw ERR_BAD_TOKEN unless data?
      dbase.register.remove(data.id)
      return data


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
      user.created_at = new Date()

      # Add user to database
      dbase.user.write(user)
        .fail ->
          log 'Error writing user to database!'
        .then (id) =>
          @get id


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
    user = @records[id]
    if user then return Q.resolve(user)
    dbase.user.read(id)
      .fail ->
        throw ERR_NO_USER
      .then (data) =>
        @records[id] = createUser(data)


  ###
   * Get a user by their email address
   *
   * - email (string)
   * > user
  ###

  getByEmail: (email) ->
    dbase.user.find(email)
      .then (id) =>
        @get id
      .fail ->
        throw ERR_NO_USER

  ###
   * Check if an email address exists in the system
   *
   * - email (string)
   * > boolean
  ###

  emailExists: (email) ->
    dbase.user.check(email)

  ###
   * Completely remove a user from the system
   * We could integrate it with @release(id), but that would write
   * it to the database, right before we instantly delete it.
   *
   * - id (int) : the user id
  ###

  remove: (id) ->
    log "Removing user #{ id }"
    @get(id).then (user) =>
      return unless user
      email = user.email
      @records[id].release()
      delete @records[id]
      dbase.user.delete id


  ###
   * Write user to database
   *
   * - user (user)
  ###

  writeUser: (user, attrs) ->
    log "Writing user: #{ user.id } with keys:", attrs
    dbase.user.write user, attrs


  ###
   * Remove a record from Node.js memory.
   * The user is still stored in the database though.
   * References to the instance will still be readable, but changes to them
   * won't be saved.
   * A user should only be released when they no longed logged in.
   *
   * - id (int) : the user id
  ###

  release: (id) ->
    log "Releasing user #{ id } from memory"
    user = @records[id]
    promise = @writeUser user
    user.release()
    delete @records[id]
    return promise


  releaseAll: ->
    @release id for id of @records
    @records = {}


  ###
   * Add a new login token.
   * It will expire after two weeks.
   *
   * - id (int) : the user id
   * - token (string) : the login token
   * > token
  ###

  addLoginToken: (id, token) ->
    dbase.login.add(id, token).then ->
      return token


  ###
   * Check that a login token is valid
   *
   * - id (int) : the user id
   * - token (string) : the login token
   * > boolean
  ###

  checkLoginToken: (id, token) ->
    dbase.login.exists(id, token)


  ###
   * Remove a specific login token
   *
   * - id (int) : the user id
   * - token (string) : the login token
  ###

  removeLoginToken: (id, token) ->
    dbase.login.remove(id, token)


  ###
   * Remove all the login tokens for a user
   *
   * - id (int) : the user id
  ###

  removeAllLoginTokens: (id) ->
    dbase.login.removeAll(id)


  ###
   * Add a new password reset token
   * Tokens are removed after 12 hours
   *
   * - id (int) : the user id
   * - token (string) : the reset token
   * > database reset token
  ###

  addResetToken: (id, token) ->
    dbase.reset.add(id, token)
    # redis.setex(key, 86400, id).then ->


  ###
   * Check that a reset token is valid
   *
   * - token (string) : the reset token
   * > int : the user id
  ###

  checkResetToken: (token) ->
    dbase.reset.get(token).fail ->
      throw ERR_BAD_TOKEN

  ###
   * Remove a reset token
   *
   * - token (string) : the reset token
  ###

  removeResetToken: (token) ->
    dbase.reset.remove(token)

module.exports = Storage
