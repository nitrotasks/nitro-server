bcrypt = require "bcrypt"
User = require "./storage"
Q = require "q"

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

  @login: (username, password) =>
    deferred = Q.defer()
    User.getByName(username)
      .fail( -> deferred.reject())
      .then (user) =>
        @compare(password, user.password).then deferred.resolve
    return deferred.promise

  @register: (name, email, pass) =>
    deferred = Q.defer()

    Q.fcall( =>
      @hash pass
    ).then( (hash) ->
      User.add name, email, hash
    ).then( (user) ->
      deferred.resolve user
    ).fail( ->
      deferred.reject()
    )

    return deferred.promise

module?.exports = Auth
