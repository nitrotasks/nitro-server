Q         = require 'kew'
dbase     = require './database'
redis     = require './redis'
Log       = require('./log')('Storage', 'green')


# -----------------------------------------------------------------------------
# Errors
# -----------------------------------------------------------------------------

ERR_OLD_EMAIL = 'err_old_email'
ERR_BAD_TOKEN = 'err_bad_token'
ERR_NO_USER   = 'err_no_user'

# -----------------------------------------------------------------------------
# User Factory
# -----------------------------------------------------------------------------

User = null

createUser = (attrs) ->
  User ?= require './user'
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

  register: (token, info) ->
    @emailExists(info.email).then (exists) ->
      if exists then throw ERR_OLD_EMAIL
      key = "register:#{ token }"
      redis.hmset key, info
      redis.expire key, 172800 # 48 hours
      return token

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
    key = 'register:' + token
    redis.hgetall(key).then (data) ->
      throw ERR_BAD_TOKEN unless data?
      redis.del key
      return data


  ###
   * This will add a user to the database
   * It will then return a new instance of the user
   *
   * - user (object) : { name, email, password }
   * - service (string) : what service to store them under
   * > User
  ###

  # Add user to database and return user as instance
  add: (user, service='native') ->
    @emailExists(user.email).then (exists) =>
      if exists then throw ERR_OLD_EMAIL

      user.pro = 0
      user.created_at = new Date()

      # Add user to database
      dbase.user.write(user)
        .fail ->
          Log 'Error writing user to database!'
        .then (id) =>
          Log 'Adding email to redis', id
          redis.hset 'users:' + service, user.email, id
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
   * - [service] (string)
   * > user
  ###

  getByEmail: (email, service='native') ->
    key = 'users:' + service
    redis.hget(key, email).then (id) =>
      throw ERR_NO_USER if id is null
      return @get id


  ###
   * Check if an email address exists in the system
   *
   * - email (string)
   * - [service] (string)
   * > boolean
  ###

  emailExists: (email, service='native') ->
    key = 'users:' + service
    redis.hexists(key, email).then (exists) ->
      return exists isnt 0


  ###
   * Completely remove a user from the system
   * We could integrate it with @release(id), but that would write
   * it to the database, right before we instantly delete it.
   *
   * - id (int) : the user id
   * - [service] (string)
  ###

  remove: (id, service='native') ->
    Log "Removing user #{ id }"
    @get(id).then (user) =>
      return unless user
      email = user.email
      @records[id].release()
      delete @records[id]
      key = 'users:' + service
      Q.all [
        redis.hdel key, user.email
        dbase.user.delete id
      ]


  ###
   * Write user to database
   *
   * - user (user)
  ###

  writeUser: (user, attrs) ->
    Log 'Writing user to database'
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
    Log "Releasing user #{ id } from memory"
    user = @records[id]
    promise = @writeUser user
    user.release()
    delete @records[id]
    return promise


  ###
   * Add a new login token.
   * It will expire after two weeks.
   *
   * - id (int) : the user id
   * - token (string) : the login token
  ###

  addLoginToken: (id, token) ->
    redis.setex "token:#{ id }:#{ token }", 1209600, Date.now()


  ###
   * Check that a login token is valid
   *
   * - id (int) : the user id
   * - token (string) : the login token
   * > boolean
  ###

  checkLoginToken: (id, token) ->
    key = 'token:' + id + ':' + token
    redis.exists(key).then (exists) ->
      return exists isnt 0


  ###
   * Remove a specific login token
   *
   * - id (int) : the user id
   * - token (string) : the login token
  ###

  removeLoginToken: (id, token) ->
    key = 'token:' + id + ':' + token
    redis.del key


  ###
   * Remove all the login tokens for a user
   *
   * - id (int) : the user id
  ###

  removeAllLoginTokens: (id) ->
    key = 'token:' + id + ':*'
    redis.keys(key).then (keys) ->
      redis.del token for token in keys


  ###
   * Add a new password reset token
   * Tokens are removed after 12 hours
   *
   * - id (int) : the user id
   * - token (string) : the reset token
  ###

  addResetToken: (id, token) ->
    key = 'forgot:' + token
    redis.setex key, 86400, id


  ###
   * Check that a reset token is valid
   *
   * - token (string) : the reset token
   * > int : the user id
  ###

  checkResetToken: (token) ->
    key = 'forgot:' + token
    redis.get(key).then (id) ->
      if id is null then throw ERR_BAD_TOKEN
      return id

  ###
   * Remove a reset token
   *
   * - token (string) : the reset token
  ###

  removeResetToken: (token) ->
    key = 'forgot:' + token
    redis.del key


  ###
   * Replace an email with another one
   * Used when a user changes their email address
   *
   * - id (int)
   * - oldEmail (string)
   * - newEmail (string)
   * - [service] (string)
  ###

  replaceEmail: (id, oldEmail, newEmail, service='native') ->
    key = 'users:' + service
    Q.all [
      redis.hdel key, oldEmail
      redis.hset key, newEmail, id
    ]


module.exports = Storage
