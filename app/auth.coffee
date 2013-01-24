bcrypt  = require "bcrypt"
User    = require "./storage"
Q       = require "q"

class Auth

  @hash: (data, salt) ->
    deferred = Q.defer()

    hash = (salt) ->
      bcrypt.hash data, salt, (err, hash) ->
        if err then return deferred.reject()
        deferred.resolve hash

    if not salt
      bcrypt.genSalt 10, (err, salt) ->
        if err then return deferred.reject()
        hash(salt)
    else hash(salt)

    return deferred.promise

  @compare: (data, hash) ->
    deferred = Q.defer()
    bcrypt.compare data, hash, (err, same) ->
      if err then return deferred.reject()
      deferred.resolve same
    return deferred.promise

  # Generate a random string
  @createToken: (len=64) ->
    token = ""
    chars = "._+-=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789$"
    for i in [1..len] by 1
      key = Math.floor(Math.random() * chars.length)
      token += chars[key]
    return token

  # Just a wrapper for generating token, saving it and then returning the token
  @saveToken: (id) =>
    token = @createToken()
    User.addLoginToken(id, token)
    token

  # Gives the user a token to use to connect to SocketIO
  @login: (email, password) =>
    deferred = Q.defer()
    User.getByEmail(email)
      .fail( -> deferred.reject("err_bad_pass") )
      .then (user) =>
        @compare(password, user.password).then (same) =>
          if not same then return deferred.reject("err_bad_pass")
          # Generate login token for user
          deferred.resolve [user.id, @saveToken(user.id)]
    return deferred.promise

  @register: (name, email, pass) =>
    deferred = Q.defer()

    valid = yes

    if name.length is 0
      deferred.reject("err_bad_name")
      valid = no

    if email.length is 0
      deferred.reject("err_bad_email")
      valid = no

    if pass.length is 0
      deferred.reject("err_bad_pass")
      valid = no

    if valid
      Q
        .fcall =>
          @hash(pass)
        .then (hash) =>
          token = @createToken()
          User.register(token, name, email, hash)
        .then (token) ->
          deferred.resolve(token)
        .fail (err) ->
          deferred.reject(err)

    return deferred.promise

  # Generate a reset password token for the user
  @generateResetToken: (email) =>
    deferred = Q.defer()
    token = @createToken()
    User.getByEmail(email)
      .then (user) ->
        User.addResetToken user.id, token
        deferred.resolve(token)
      .fail ->
        deferred.reject "err_bad_email"
    deferred.promise

module?.exports = Auth
