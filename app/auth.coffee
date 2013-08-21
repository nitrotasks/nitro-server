bcrypt  = require 'bcrypt'
User    = require './user'
oauth   = require './oauth'
Q       = require 'q'
Keys    = require './keychain'

class Auth

  @oauth:

    request: oauth.request
    verify: oauth.verify
    access: oauth.access

    login: (service, access) ->
      deferred = Q.defer()
      oauth.userinfo(service, access).then ([email, name]) ->
        User.getByEmail(email, service)

          # User already exists, so we can sign them in
          .then (user) ->
            deferred.resolve [
              user.id
              Auth.saveToken(user.id)
              user.email
              user.name
              user.pro
            ]

          # User doesn't exist, so we register them
          .fail ->
            User.add({
              name: name
              email: email
              password: '*'
              service: service })
              .then (user) ->
                deferred.resolve [
                  user.id
                  Auth.saveToken(user.id)
                  user.email
                  user.name
                  user.pro
                ]
              .fail (msg) ->
                deferred.reject msg

      return deferred.promise

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
    token = ''
    chars = '-_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
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
      .then (user) =>
        @compare(password, user.password).then (same) =>
          if not same then return deferred.reject('err_bad_pass')
          # Generate login token for user
          deferred.resolve [
            user.id
            @saveToken(user.id)
            user.email
            user.name
            user.pro
          ]
      .fail ->
        deferred.reject('err_bad_pass')
    return deferred.promise

  @register: (name, email, pass) =>
    deferred = Q.defer()

    valid = yes

    if name.length is 0
      deferred.reject('err_bad_name')
      valid = no

    if email.length is 0
      deferred.reject('err_bad_email')
      valid = no

    if pass.length is 0
      deferred.reject('err_bad_pass')
      valid = no

    if valid
      Q.fcall =>
        @hash(pass)
      .then (hash) =>
        token = @createToken(22)
        User.register(token, name, email, hash)
      .then (token) ->
        deferred.resolve(token)
      .fail (err) ->
        deferred.reject(err)

    return deferred.promise

  @verifyRegistration: (token) ->
    deferred = Q.defer()
    Q.fcall ->
      User.getRegistration(token)
    .then (user) ->
      User.add
        name: user.name
        email: user.email
        password: user.password
    .then (user) ->
      deferred.resolve(user)
    .fail (err) ->
      deferred.reject(err)
    return deferred.promise

  # Generate a reset password token for the user
  @generateResetToken: (email) =>
    deferred = Q.defer()
    token = @createToken(22)
    User.getByEmail(email)
      .then (user) ->
        User.addResetToken user.id, token
        deferred.resolve(token)
      .fail ->
        deferred.reject 'err_bad_email'
    deferred.promise

module?.exports = Auth
