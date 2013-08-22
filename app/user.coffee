nodeRedis = require 'redis'
Q         = require 'q'
_         = require 'lodash'
dbase     = require './database'
Log       = require('./log')('User', 'green')


#==============================================================================
# Data structure
#==============================================================================

#   user = {
#     id: int,
#     name: string,
#     email: string,
#     password: string,
#     pro: boolean,
#     data_Task: object,/
#     data_List: object,
#     data_Time: object,
#     index_Task: int,
#     index_List: int,
#     created_at: date,
#     updated_at: date
#   };


#==============================================================================
# Databases
#==============================================================================

# Connect to MySQL database
dbase.connect()

# Connect to Redis
redis = nodeRedis.createClient()
# redis.flushdb()


#==============================================================================
# User Class
#==============================================================================

class User
  @records: {}

  # Register user data in a temporary key until they have verified their account
  @register: (token, name, email, password) ->
    deferred = Q.defer()
    @emailExists(email).then (exists) ->
      if exists then return deferred.reject('err_old_email')
      key = "register:#{token}"
      redis.hmset key,
        name: name
        email: email
        password: password
      redis.expire(key, 172800) # 48 hours
      deferred.resolve(token)
    return deferred.promise

  # Check if registration token exists
  @getRegistration: (token) ->
    deferred = Q.defer()
    redis.hgetall "register:#{token}", (err, data) ->
      if err or not data?
        return deferred.reject("err_bad_token")
      deferred.resolve data
      # Token is deleted to avoid duplications
      redis.del "register:#{token}"
    return deferred.promise

  # Add user to database and return user as instance
  @add: (options) =>
    deferred = Q.defer()

    # Make sure email is unique
    @emailExists(options.email).then (exists) =>

      if exists then return deferred.reject("err_old_email")

      user =
        name: options.name
        password: options.password
        email: options.email
        pro: 0

      # Add user to database
      dbase.user.write(user)
        .then (id) =>

          # Add ID to lookup table
          options.service ?= "native"
          redis.hset "users:#{options.service}", options.email, id

          # Load user into memory and resolve
          @get(id).then deferred.resolve, console.error

        .fail ->
          Log 'Error writing user to database!'

    return deferred.promise

  # Get user from database by ID
  @get: (id) =>
    deferred = Q.defer()
    user = @records[id]
    if not user
      dbase.user.read(id)
        .then (data) =>
          user = @records[id] = new @(data)
          deferred.resolve user._clone()
        .fail (err) ->
          deferred.reject("err_no_user")
    else
      deferred.resolve user._clone()
    return deferred.promise

  @getByEmail: (email, service="native") ->
    deferred = Q.defer()
    redis.hget "users:#{service}", email, (err, id) =>
      if id is null then return deferred.reject("User not found")
      @get(id)
        .then(deferred.resolve, deferred.reject)
    return deferred.promise

  @emailExists: (email, service="native") ->
    deferred = Q.defer()
    redis.hexists "users:#{service}", email, (err, exists) ->
      if exists is 0
        return deferred.resolve no
      else
        return deferred.resolve yes
    return deferred.promise

  @remove: (id, service="native") =>
    deferred = Q.defer()
    @get(id).then (user) =>
      return unless user
      @release(id)
      redis.hdel "users:native", user.email
      dbase.user.delete(id).then deferred.resolve
      return
    return deferred.promise

  # Remove record from JS memory
  # User is still stored in Database
  # Instances will still work
  # Should only be used when all users have logged out though
  # Because you can't reconnect the instance to the record
  @release: (id) =>
    Log "Removing record #{ id }"
    dbase.user.write @records[id]
    @records[id]._released = true
    delete @records[id]

  # Login tokens expire after 2 weeks
  @addLoginToken: (id, token) =>
    redis.setex "token:#{id}:#{token}", 1209600, Date.now()

  @checkLoginToken: (id, token) =>
    deferred = Q.defer()
    redis.exists "token:#{id}:#{token}", (err, exists) ->
      if err then return deferred.reject(err)
      if exists is 0 then return deferred.resolve(no)
      else return deferred.resolve(yes)
    deferred.promise

  # Token will expire in 24 hours (86400 seconds)
  @addResetToken: (id, token) ->
    redis.setex "forgot:#{token}", 86400, id

  @checkResetToken: (token) ->
    deferred = Q.defer()
    redis.get "forgot:#{token}", (err, id) ->
      if err then return deferred.reject(err)
      if id is null then return deferred.reject("err_bad_token")
      deferred.resolve id
    deferred.promise

  @removeResetToken: (token) ->
    redis.del "forgot:#{token}"


  # Notifications
  @addNotification: (uid, time, type) ->
    # notifications:<time> = {
    #   <uid> = <type>
    # }


  # ----------------
  # Instance Methods
  # ----------------

  constructor: (atts) ->
    @_load atts if atts
    # Throttle writes to once per 5 seconds
    @_write = _.throttle @__write, 5000

  _clone: =>
    Object.create(this)

  # Load attributes
  _load: (atts) =>
    for key, value of atts
      @[key] = value
    return @

  # Write user data to disk (used with _.throttle in constructor)
  __write: =>
    Log "Writing data to disk"
    # Don't save to disk if the user has been released
    return if @_released
    # Create user object
    dbase.user.write(this)

  # Change a value
  _set: (key, value) =>
    Log "Updating #{key}"
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
    key = "data_#{className}"
    # Easy way to replace an entire key
    if replaceWith?
      @[key] = replaceWith
    # Create the object if it doesn't exist
    else if not @.hasOwnProperty(key)
      @[key] = {}
    @[key]

  # Get the index for a dataset
  index: (className) =>
    key = "index_#{className}"
    index = @[key]
    return index ? @_set(key, 0)

  # Increase the index for a class by one
  incrIndex: (className) =>
    key = "index_#{className}"
    value = @[key] ? 0
    @_set key, ++value
    return value

  # Change data
  save: (className) =>
    @_set("data_#{className}", @["data_#{className}"])
    return

  # Change Password
  changePassword: (newPassword) =>
    deferred = Q.defer()
    # Delete login tokens
    redis.keys "token:#{@id}:*", (err, data) ->
      for token in data
        redis.del token
      deferred.resolve
    # Save password
    @_set("password", newPassword)
    return deferred.promise

  # Change email
  changeEmail: (newEmail, service="native") =>
    deferred = Q.defer()
    redis.hdel "users:#{service}", @email
    redis.hset "users:#{service}", newEmail, @id, deferred.resolve
    @_set("email", newEmail)
    deferred.promise

  changeProStatus: (status) =>
    @_set("pro", status)

module?.exports = User
