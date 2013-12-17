###
 * Storage Controller
###

Q         = require 'kew'
_         = require 'lodash'
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
      if exists then throw new Error ERR_OLD_EMAIL

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
      .fail (err) ->
        throw new Error ERR_NO_USER
      .then (data) =>
        @records[id] = new User(data)

  getByEmail: (email, service='native') ->
    deferred = Q.defer()
    redis.hget "users:#{ service }", email, deferred.makeNodeResolver()
    deferred.then (id) =>
      if id is null then return deferred.reject new Error ERR_NO_USER
      return @get(id)

  emailExists: (email, service='native') ->
    deferred = Q.defer()
    redis.hexists "users:#{ service }", email, deferred.makeNodeResolver()
    return deferred.then (exists) ->
      return exists isnt 0

  remove: (id, service='native') ->
    Log "Removing record #{ id }"

    @get(id).then (user) =>
      return unless user
      email = user.email

      # We could use @release(id), but then it would write
      # it to the database, and then we instantly delete it
      @records[id]._released = true
      delete @records[id]

      Q.all [
        redis.hdel "users:#{ service }", user.email
        dbase.user.delete id
      ]

  # Write user to database
  writeUser: (user) ->
    Log 'Writing user to database'
    dbase.user.write user

  # Remove record from JS memory
  # User is still stored in Database
  # Instances will still work
  # Should only be used when all users have logged out though
  # Because you can't reconnect the instance to the record
  release: (id) ->
    Log "Releasing record #{ id }"
    promise = @writeUser @records[id]
    @records[id]._released = true
    delete @records[id]
    return promise

  # Login tokens expire after 2 weeks
  addLoginToken: (id, token) ->
    redis.setex "token:#{ id }:#{ token }", 1209600, Date.now()

  checkLoginToken: (id, token) ->
    deferred = Q.defer()
    redis.exists "token:#{ id }:#{ token }", (err, exists) ->
      if err then return deferred.reject err
      deferred.resolve exists isnt 0
    return deferred.promise

  removeLoginToken: (id, token) ->
    Q.nfcall redis.del, "token:#{ id }:#{ token }"

  removeAllLoginTokens: (id) ->
    deferred = Q.nfcall redis.keys, "token:#{ id }:*"
    deferred.then (data) ->
      redis.del token for token in data

  # Token will expire in 24 hours (86400 seconds)
  addResetToken: (id, token) ->
    redis.setex "forgot:#{ token }", 86400, id

  checkResetToken: (token) ->
    deferred = Q.defer()
    redis.get "forgot:#{ token }", (err, id) ->
      if err then return deferred.reject err
      if id is null then return deferred.reject new Error ERR_BAD_TOKEN
      deferred.resolve id
    return deferred.promise

  removeResetToken: (token) ->
    redis.del "forgot:#{ token }"

  replaceEmail: (id, oldEmail, newEmail, service='native') ->
    Q.all [
      Q.nfcall redis.hdel, "users:#{ service }", oldEmail
      Q.nfcall redis.hset, "users:#{ service }", newEmail, id
    ]
  
module.exports = Storage
