nodeRedis = require 'redis'
Q         = require 'kew'
_         = require 'lodash'
dbase     = require './database'
Log       = require('./log')('User', 'green')


#==============================================================================
# Data structure
#==============================================================================

#   user = {
#     id:          int,
#     name:        string,
#     email:       string,
#     password:    string,
#     pro:         boolean,
#     data_task:   object,
#     data_list:   object,
#     data_time:   object,
#     index_task:  int,
#     index_list:  int,
#     created_at:  date,
#     updated_at:  date
#   };

#==============================================================================
# Errors
#==============================================================================

ERR_OLD_EMAIL = new Error 'err_old_email'
ERR_BAD_TOKEN = new Error 'err_bad_token'
ERR_NO_USER   = new Error 'err_no_user'

#==============================================================================
# Databases
#==============================================================================

# Connect to MySQL database
dbase.connect()

# Connect to Redis
redis = nodeRedis.createClient()

#==============================================================================
# User Class
#==============================================================================

class User

  ###
   * User._redis
   * Expose the redis connection to make testing easier
  ###

  @_redis: redis

  ###
   * User.records
   * This object holds all of the user instances
   * that are currently stored in memory.
  ###

  @records: {}

  ###
   * User.register
   * This will store user data in a temporary key until
   * they have verified their account.
   * The email used must not exist in the database.
   * - token (string) : special id assigned to the data
   * - user (object) : { name, email, password }
   * > token
   * ! err_old_email
  ###

  @register: (token, info) ->
    @emailExists(info.email).then (exists) ->
      if exists then throw ERR_OLD_EMAIL
      key = "register:#{ token }"
      redis.hmset key, info
      redis.expire key, 172800 # 48 hours
      return token

  ###
   * User.getRegistration
   * This will check if registration token exists.
   * If the token can't be found an error will be thrown.
   * If it is found then the registration will be deleted
   * and the user data returned.
   * - token (string) : the registration token
   * > return user data
   * ! err_bad_token
  ###

  @getRegistration: (token) ->
    deferred = Q.defer()
    redis.hgetall "register:#{ token }", deferred.makeNodeResolver()
    return deferred.then (data) ->
      if not data? then throw ERR_BAD_TOKEN
      redis.del "register:#{ token }"
      return data


  ###
   * User.add
   * This will add a user to the database
   * It will then return a new instance of the user
   * - user (object) : { name, email, password }
  ###

  # Add user to database and return user as instance
  @add: (user, service='native') =>
    @emailExists(user.email).then (exists) =>
      if exists then throw ERR_OLD_EMAIL

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
          @get(id).fail console.error

  # Get user from database by ID
  @get: (id) =>
    deferred = Q.defer()
    user = @records[id]
    if not user
      dbase.user.read(id)
        .fail (err) ->
          deferred.reject ERR_NO_USER
        .then (data) =>
          user = @records[id] = new User(data)
          deferred.resolve user
    else
      deferred.resolve user
    return deferred.promise

  @getByEmail: (email, service='native') ->
    deferred = Q.defer()
    redis.hget "users:#{ service }", email, deferred.makeNodeResolver()
    deferred.then (id) =>
      if id is null then return deferred.reject ERR_NO_USER
      return @get(id)

  @emailExists: (email, service='native') ->
    deferred = Q.defer()
    redis.hexists "users:#{ service }", email, deferred.makeNodeResolver()
    return deferred.then (exists) ->
      return exists isnt 0

  @remove: (id, service='native') =>
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

  # Remove record from JS memory
  # User is still stored in Database
  # Instances will still work
  # Should only be used when all users have logged out though
  # Because you can't reconnect the instance to the record
  @release: (id) =>
    Log "Releasing record #{ id }"
    promise = dbase.user.write @records[id]
    @records[id]._released = true
    delete @records[id]
    return promise

  # Login tokens expire after 2 weeks
  @addLoginToken: (id, token) =>
    redis.setex "token:#{ id }:#{ token }", 1209600, Date.now()

  @checkLoginToken: (id, token) =>
    deferred = Q.defer()
    redis.exists "token:#{ id }:#{ token }", (err, exists) ->
      if err then return deferred.reject err
      deferred.resolve exists isnt 0
    return deferred.promise

  # Token will expire in 24 hours (86400 seconds)
  @addResetToken: (id, token) ->
    redis.setex "forgot:#{ token }", 86400, id

  @checkResetToken: (token) ->
    deferred = Q.defer()
    redis.get "forgot:#{ token }", (err, id) ->
      if err then return deferred.reject err
      if id is null then return deferred.reject ERR_BAD_TOKEN
      deferred.resolve id
    return deferred.promise

  @removeResetToken: (token) ->
    redis.del "forgot:#{ token }"


#==============================================================================
# INSTANCE METHODS
#==============================================================================

  constructor: (atts) ->
    @_load atts if atts
    # Throttle writes to once per 5 seconds
    @_write = _.throttle @__write, 5000

  # Load attributes
  _load: (atts) =>
    @[key] = value for key, value of atts
    return this

  # Write user data to disk (used with _.throttle in constructor)
  __write: =>
    # Don't save to disk if the user has been released
    return if @_released
    Log 'Writing data to disk'
    # Create user object
    dbase.user.write(this)

  # Change a value
  _set: (key, value) =>
    # Update local object
    @_update(key, value)
    # Save to disk
    @_write()
    return value

  # Update record without writing to disk
  _update: (key, value) =>
    records = @constructor.records
    if @id of records
      records[@id][key] = value

  # Just an easy way to get user data
  data: (className, replaceWith) =>
    key = "data_#{ className }"
    # Easy way to replace an entire key
    if replaceWith?
      @[key] = replaceWith
    # Create the object if it doesn't exist
    else if not @.hasOwnProperty(key)
      @[key] = {}
    @[key]

  # Get the index for a dataset
  index: (className) =>
    key = "index_#{ className }"
    index = @[key]
    return index ? @_set(key, 0)

  # Increase the index for a class by one
  incrIndex: (className) =>
    key = "index_#{ className }"
    value = @[key] ? 0
    @_set key, ++value
    return value

  # Change data
  save: (className) =>
    @_set "data_#{ className }", @["data_#{ className }"]
    return

  # Change Password
  setPassword: (newPassword) =>
    deferred = Q.defer()
    # Delete login tokens
    redis.keys "token:#{ @id }:*", (err, data) ->
      for token in data
        redis.del token
      deferred.resolve
    # Save password
    @_set('password', newPassword)
    return deferred.promise

  # Change email
  setEmail: (newEmail, service='native') =>
    deferred = Q.defer()
    redis.hdel "users:#{ service }", @email
    redis.hset "users:#{ service }", newEmail, @id, deferred.makeNodeResolver()
    @_set 'email', newEmail
    return deferred.promise

  setPro: (status) =>
    @_set 'pro', status

module.exports = User
