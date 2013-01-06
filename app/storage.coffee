redis   = require("redis").createClient(null, null, {detect_buffers: true})
Q       = require "q"
shrink  = require "./shrink"
msgpack = require "msgpack"

# Set up
redis.flushdb()
redis.setnx "users:index", "0"

# Users
class User
  @records: {}

  # Add user to database and return user as instance
  @add: (name, email, password, fn) =>

    deferred = Q.defer()
    self = @

    @emailExists(email).then (exists) ->
      if exists then return deferred.reject("err_old_email")
      redis.incr "users:index", (err, id) ->
        user =
          id: id.toString()
          name: name
          password: password
          email: email
          has_pro: "0"
          created_at: Date.now().toString()
        # Save to redis
        redis.hmset "users:#{id}", user
        # Add to lookup
        redis.hset "users:email", email, id
        # Resolve promise
        self.get(id).then deferred.resolve

    return deferred.promise

  # Get user from database by ID
  @get: (id) =>
    deferred = Q.defer()
    user = @records[id]
    if not user
      # Get data as a buffer so that we can unpack the msgpack encoding
      redis.hgetall new Buffer("users:#{id}"), (err, obj) =>
        if obj
          user = @records[id] = new @(obj)
          deferred.resolve user._clone()
        else
          deferred.reject("User not found")
    else
      deferred.resolve user._clone()
    return deferred.promise

  @getByEmail: (email) ->
    deferred = Q.defer()
    redis.hget "users:email", email, (err, id) =>
      if id is null then return deferred.reject("Email not found")
      @get(id)
        .then(deferred.resolve, deferred.reject)
    deferred.promise

  @emailExists: (email) ->
    deferred = Q.defer()
    redis.hexists "users:email", email, (err, exists) ->
      if exists is 0
        return deferred.resolve no
      else
        return deferred.resolve yes
    deferred.promise

  @remove: (id) =>
    deferred = Q.defer()
    @get(id).then (user) =>
      return unless user
      @release(id)
      redis.hdel "users:email", user.email
      redis.del "users:#{id}", deferred.resolve
      true
    deferred.promise

  # Remove record from JS memory
  # User is still stored in Redis
  # Instances will still work
  # Should only be used when all users have logged out though
  # Because you can't reconnect the instance to the record
  @release: (id) =>
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

  constructor: (atts) ->
    @_load atts if atts

  # Instance Methods

  _clone: =>
    Object.create(this)

  # Load attributes
  _load: (atts) =>
    for key, value of atts
      if key.slice(0,5) is "data:"
        @[key] = shrink.expand msgpack.unpack value
      else
        @[key] = value.toString()
    this

  # Change a value
  _set: (key, value) =>
    deferred = Q.defer()
    # Update local object
    @_update(key, value)
    # Compress data
    if key.slice(0,5) is "data:"
      value = msgpack.pack shrink.compress value
    # Update redis
    redis.hset "users:#{@id}", key, value, =>
      redis.hset "users:#{@id}", "updated_at", Date.now().toString()
      deferred.resolve()
    deferred.promise

  # Update record
  _update: (key, value) =>
    records = @constructor.records
    if @id of records
      records[@id][key] = value

  # Just an easy way to get user data
  data: (className, data) =>
    key = "data:#{className}"
    if data
      @[key] = data
    @[key]

  # Get the index for a dataset
  index: (className) =>
    key = "index:#{className}"
    index = @[key]
    if !index
      @_set key, "0"
      return "0"
    else
      return index

  # Increase the index for a dataset by one
  incrIndex: (className) =>
    deferred = Q.defer()
    key = "index:#{className}"
    value = @[key] or "0"
    @_update key, (parseInt(value, 10) + 1).toString()
    redis.hincrby "users:#{@id}", key, 1, deferred.resolve
    deferred.promise

  # Change data
  save: (className) =>
    deferred = Q.defer()
    @_set("data:#{className}", @["data:#{className}"]).then(deferred.resolve)
    deferred.promise

  # Change Password
  changePassword: (newPassword) =>
    deferred = Q.defer()
    @_set("password", newPassword).then(deferred.resolve)
    deferred.promise

  # Change email
  changeEmail: (newEmail) =>
    deferred = Q.defer()
    redis.hdel "users:email", @email
    redis.hset "users:email", newEmail, @id
    @_set("email", newEmail).then(deferred.resolve)
    deferred.promise

  changeProStatus: (status) =>
    deferred = Q.defer()
    @_set("has_pro", status).then(deferred.resolve)
    deferred.promise

module?.exports = User
