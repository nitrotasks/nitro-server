bcrypt  = require "bcrypt"
User    = require "./storage"
Q       = require "q"

class Auth

  @hash: (data) ->
    deferred = Q.defer()
    bcrypt.genSalt 10, (err, salt) ->
      if err then return deferred.reject()
      bcrypt.hash data, salt, (err, hash) ->
        if err then return deferred.reject()
        deferred.resolve hash
    return deferred.promise

  @compare: (data, hash) ->
    deferred = Q.defer()
    bcrypt.compare data, hash, (err, same) ->
      if err then return deferred.reject()
      deferred.resolve same
    return deferred.promise

  @login: (email, password) =>
    deferred = Q.defer()
    User.getByEmail(email)
      .fail( -> deferred.reject("err_bad_pass") )
      .then (user) =>
        @compare(password, user.password).then (same) ->
          if same then deferred.resolve() else deferred.reject("err_bad_pass")
    return deferred.promise

  @register: (name, email, pass) =>
    deferred = Q.defer()

    Q.fcall( =>
      @hash pass
    ).then( (hash) ->
      User.add name, email, hash
    ).then( (user) ->
      deferred.resolve user
    ).fail( (err) ->
      deferred.reject(err)
    )

    return deferred.promise

module?.exports = Auth
