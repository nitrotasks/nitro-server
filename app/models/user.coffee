throttle = require '../utils/throttle'

### ---------------------------------------------------------------------------

Recommended data structure

  user = {
    id:          int
    name:        string
    email:       string
    password:    string
    pro:         boolean
    data_task:   object
    data_list:   object
    data_time:   object
    data_pref:   object
    index_task:  int
    index_list:  int
    created_at:  date
    updated_at:  date
  }

#### --------------------------------------------------------------------------

class User

  ###
   * Create a new User instance
   *
   * - [attrs] (object) : optional attributes to load in
  ###

  constructor: (attrs) ->
    @_load attrs if attrs
    @_write = throttle @_write, 5000


  # Resolve cyclic dependency with Storage controller
  module.exports = User
  Storage = require '../controllers/storage'


  ###
   * (private) Load attributes
   * Just copies keys from one object into the user instance.
   *
   * - attrs (object) : object to copy keys from
   * > this
  ###

  _load: (attrs) ->
    @[key] = value for own key, value of attrs
    return this


  ###
   * (private) Write to database
   * Writes the user data to disk.
   * Will do nothing if the user has been released from memoru.
  ###

  _write: (keys) =>
    return if @_released
    Storage.writeUser this, keys


  ###
   * Set a value on the instance
   * Will also write the change to disk
   *
   * - key (string)
   * - value (*)
   * > value
  ###

  set: (key, value) ->
    @[key] = value
    @_write key
    return value


  ###
   * Get or set user data
   * Prefixes keys with data_.
   * Will create an empty object if the key doesn't exist
   *
   * - key (string)
   * - [replaceWith] (object) : optional object to replace the data with
   * > data
  ###

  data: (key, replaceWith) ->
    key = 'data_' + key
    if replaceWith?
      @[key] = replaceWith
      return replaceWith
    if not this.hasOwnProperty(key)
      return @[key] = {}
    return @[key]


  ###
   * Save data to disk
   *
   * - key (string)
  ###

  save: (key) ->
    key = 'data_' + key
    @_write key


  ###
   * Get the index for a data set
   * Will be set to 0 if it doesn't exist
   *
   * - key (string)
   * > int
  ###

  index: (key) ->
    key = 'index_' + key
    index = @[key]
    return index ? @set key, 0


  ###
   * Increment the index for a data set by one
   * Will be set to 1 if the key doesn't exist
   *
   * - key (string)
   * > int
  ###

  incrIndex: (key) ->
    key = 'index_' + key
    value = @[key] ? 0
    @set key, ++value
    return value


  ###
   * Change a users password and remove all their login tokens
   *
   * - password (string) : the hash of the password
  ###

  setPassword: (password) ->
    @set 'password', password
    Storage.removeAllLoginTokens(@id)


  ###
   * Change a users email and update the email lookup table
   *
   * - email (string) : the email to change to
  ###

  setEmail: (email) ->
    oldEmail = @email
    @set 'email', email
    Storage.replaceEmail @id, oldEmail, email, @service


  ###
   * Mark the user as released from memory
  ###

  release: ->
    @_released = true

