Q         = require 'kew'
dbase     = require './database'
Log       = require('./log')('Storage', 'green')

# -----------------------------------------------------------------------------
# Errors
# -----------------------------------------------------------------------------

ERR_OLD_EMAIL = 'err_old_email'
ERR_BAD_TOKEN = 'err_bad_token'
ERR_NO_USER   = 'err_no_user'

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
      if exists then throw new Error ERR_OLD_EMAIL
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
    deferred = Q.defer()
    redis.hgetall "register:#{ token }", deferred.makeNodeResolver()
    return deferred.then (data) ->
      if not data? then throw new Error ERR_BAD_TOKEN
      redis.del "register:#{ token }"
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
      if exists then throw Error ERR_OLD_EMAIL

      user.pro = 0
      user.created_at = new Date()

      # Add user to database
      dbase.user.write(user)
        .fail ->
          Log 'Error writing user to database!'
        .then (id) =>
          Log 'Setting user to redis', id
          # Add ID to lookup table
          redis.hset "users:#{ service }", user.email, id
          # Load user into memory
          @get(id)

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
        throw new Error ERR_NO_USER
      .then (data) =>
        @records[id] = new User(data)


  ###
   * Get a user by their email address
   *
   * - email (string)
   * - [service] (string)
   * > user
  ###

  getByEmail: (email, service='native') ->
    Q.nfcall(redis.hget, 'users:' + service, email).then (id) =>
      if id is null then throw Error ERR_NO_USER
      @get id


  ###
   * Check if an email address exists in the system
   *
   * - email (string)
   * - [service] (string)
   * > boolean
  ###

  emailExists: (email, service='native') ->
    Q.nfcall(redis.hexists, 'users:' + service, email).then (exists) ->
      return exists isnt 0


  ###
   * Completely remove a user from the system
   *
   * - id (int) : the user id
   * - [service] (string)
  ###

  remove: (id, service='native') ->
    Log "Removing user #{ id }"

    @get(id).then (user) =>
      return unless user
      email = user.email

      # We could use @release(id), but then it would write
      # it to the database, and then we instantly delete it
      @records[id].release()
      delete @records[id]

      Q.all [
        Q.nfcall redis.hdel, 'users:' + service, user.email
        dbase.user.delete id
      ]

  ###
   * Write user to database
   *
   * - user (user)
  ###

  writeUser: (user) ->
    Log 'Writing user to database'
    dbase.user.write user

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
    Q.nfcall(redis.exists, "token:#{ id }:#{ token }").then (exists) ->
      return exists isnt 0

  ###
   * Remove a specific login token
   *
   * - id (int) : the user id
   * - token (string) : the login token
  ###

  removeLoginToken: (id, token) ->
    Q.nfcall redis.del, "token:#{ id }:#{ token }"


  ###
   * Remove all the login tokens for a user
   *
   * - id (int) : the user id
  ###

  removeAllLoginTokens: (id) ->
    Q.nfcall(redis.keys, "token:#{ id }:*").then (keys) ->
      redis.del token for token in keys

  ###
   * Add a new password reset token
   * Tokens are removed after 12 hours
   *
   * - id (int) : the user id
   * - token (string) : the reset token
  ###

  addResetToken: (id, token) ->
    redis.setex 'forgot:' + token, 86400, id


  ###
   * Check that a reset token is valid
   *
   * - token (string) : the reset token
   * > int : the user id
  ###

  checkResetToken: (token) ->
    Q.nfcall(redis.get, 'forgot:' + token).then (id) ->
      if id is null then throw Error ERR_BAD_TOKEN
      return id

  ###
   * Remove a reset token
   *
   * - token (string) : the reset token
  ###

  removeResetToken: (token) ->
    redis.del "forgot:#{ token }"


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
    Q.all [
      Q.nfcall redis.hdel, "users:#{ service }", oldEmail
      Q.nfcall redis.hset, "users:#{ service }", newEmail, id
    ]


module.exports = Storage
