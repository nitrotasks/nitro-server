redis   = require("redis")
Q       = require "q"
shrink  = require "./shrink"
msgpack = require "msgpack"
fs      = require "fs"
_       = require "lodash"

if process.env.REDISTOGO_URL
  rtg = require("url").parse(process.env.REDISTOGO_URL)
  redis = redis.createClient(rtg.port, rtg.hostname)
  redis.auth(rtg.auth.split(":")[1])
else
  redis = redis.createClient()

# Set up
# redis.flushdb()
redis.setnx "users:index", "-1"

# ---------------
# Private Methods
# ---------------

File =

  # Write user object to file
  write: (user) ->
    deferred = Q.defer()
    obj =
      id: parseInt(user.id, 10)
      name: user.name
      email: user.email
      password: user.password
      pro: user.pro
      data_Task: user.data_Task or {}
      data_List: user.data_List or {}
      data_Time: user.data_Time or {}
      index_Task: user.index_Task or 0
      index_List: user.index_List or 0
      created_at: parseInt(user.created_at, 10)
      updated_at: Date.now()
    [path, folder] = User.filename(obj.id)
    # Compress object
    data = msgpack.pack shrink.compress(obj)
    # Make sure folder exists
    if obj.id % 100 is 0
      fs.mkdir folder, ->
        # Save file
        fs.writeFile(path, data, deferred.resolve)
    else
      # Save file
      fs.writeFile(path, data, deferred.resolve)
    return deferred.promise

  # Read user file
  read: (id) ->
    deferred = Q.defer()
    [path, folder] = User.filename(id)
    fs.readFile path, (err, buffer) =>
      if err then return deferred.reject("err_no_user")
      data = shrink.expand msgpack.unpack(buffer)
      deferred.resolve(data)
    return deferred.promise

  # Delete user file
  del: (id) ->
    deferred = Q.defer()
    path = User.filename(id)[0]
    fs.unlink path, deferred.resolve
    return deferred.promise

# Cache filenames
__cache__filename = {}


# ----------
# User Class
# ----------

class User
  @records: {}

  # Generate filename for a user ID
  # 4321 -> ["users/4300-4399/4321.usr", "users/4300-4399", "4321.usr"]
  @filename: (id) ->
    if id of __cache__filename
      return __cache__filename[id]
    else
      group  = Math.floor(parseInt(id,10)/100)*100
      max    = group + 99
      folder = "users/#{group}-#{max}"
      file   = "#{id}.usr"
      path   = "#{folder}/#{file}"
      array  = [path, folder, file]
      __cache__filename[id] = array
      return array

  # Register user data in a temporary key until they have verified their account
  @register: (token, name, email, password) ->
    deferred = Q.defer()
    @emailExists(email).then (exists) ->
      if exists then return deferred.reject("err_old_email")
      key = "register:#{token}"
      redis.hmset key,
        name: name
        email: email
        password: password
      # Expire this key in 48 hours
      redis.expire(key, 172800)
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
    @emailExists(options.email).then (exists) =>
      if exists then return deferred.reject("err_old_email")
      redis.incr "users:index", (err, id) =>
        user =
          id: id
          name: options.name
          password: options.password
          email: options.email
          pro: 0
          created_at: Date.now()
        # Add to lookup
        options.service ?= "native"
        redis.hset "users:#{options.service}", options.email, id
        # Resolve promise
        File.write(user).then =>
          @get(id)
            .then deferred.resolve, console.error
    return deferred.promise

  # Get user from database by ID
  @get: (id) =>
    deferred = Q.defer()
    user = @records[id]
    if not user
      File.read(id)
        .then (data) =>
          user = @records[id] = new @(data)
          deferred.resolve user._clone()
        .fail (err) ->
          deferred.reject(err)
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
      File.del(id).then deferred.resolve
      return
    return deferred.promise

  # Remove record from JS memory
  # User is still stored in Redis
  # Instances will still work
  # Should only be used when all users have logged out though
  # Because you can't reconnect the instance to the record
  @release: (id) =>
    File.write @records[id]
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
    # Save filename
    @_filename = @.constructor.filename(@id)

  _clone: =>
    Object.create(this)

  # Load attributes
  _load: (atts) =>
    for key, value of atts
      @[key] = value
    return @

  # Write user data to disk (used with _.throttle in constructor)
  __write: =>
    # Don't save to disk if the user has been released
    return if @_released
    # Create user object
    File.write(@)

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
