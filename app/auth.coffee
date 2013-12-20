Q       = require 'kew'
bcrypt  = require 'bcrypt'
crypto  = require 'crypto'
Storage = require './storage'
oauth   = require './oauth'
Keys    = require './keychain'

Auth =

  oauth:

    request: oauth.request
    verify: oauth.verify
    access: oauth.access

    login: (service, access) ->
      deferred = Promise.defer()

      oauth.userinfo(service, access).then ([email, name]) ->

        Storage.getByEmail(email, service)

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
          .otherwise ->
            Storage.add({
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

  ###
   * Hash some data using bcrypt
   * The salt is randomly generated.
   *
   * - data (string)
   * > data
  ###

  hash: (data) ->
    bcrypt.hash data, 10, (err, hash) ->

  compare: (data, hash) ->
    deferred = Q.defer()
    bcrypt.compare data, hash, (err, same) ->
      if err then return deferred.reject()
      deferred.resolve same
    return deferred.promise

  # Wrap crypto.randomBytes in a promise
  randomBytes: Q.bindPromise crypto.randomBytes, crypto

  # Generate a random string
  createToken: (len=64) ->
    byteLen = Math.ceil len * 0.75
    Auth.randomBytes(byteLen).then (bytes) ->
      return bytes.toString 'base64'

  # Just a wrapper for generating token, saving it and then returning the token
  saveToken: (id) ->
    Auth.createToken().then (token) ->
      Storage.addLoginToken id, token
      return token

  # Gives the user a token to use to connect to SocketIO
  login: (email, password) ->
    deferred = Q.defer()
    Storage.getByEmail(email)
      .then (user) ->
        Auth.compare(password, user.password).then (same) ->
          if not same then return deferred.reject('err_bad_pass')
          # Generate login token for user
          deferred.resolve [
            user.id
            Auth.saveToken(user.id)
            user.email
            user.name
            user.pro
          ]
      .fail ->
        deferred.reject('err_bad_pass')
    return deferred.promise

  register: (name, email, pass) ->
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
      Q.fcall ->
        Auth.hash(pass)
      .then (hash) ->
        token = Auth.createToken(22)
        Storage.register(token, name, email, hash)
      .then (token) ->
        deferred.resolve(token)
      .fail (err) ->
        deferred.reject(err)

    return deferred.promise

  verifyRegistration: (token) ->
    deferred = Q.defer()
    Q.fcall ->
      Storage.getRegistration(token)
    .then (user) ->
      Storage.add
        name: user.name
        email: user.email
        password: user.password
    .then (user) ->
      deferred.resolve(user)
    .fail (err) ->
      deferred.reject(err)
    return deferred.promise

  # Generate a reset password token for the user
  generateResetToken: (email) ->
    deferred = Q.defer()
    token = Auth.createToken(22)
    Storage.getByEmail(email)
      .then (user) ->
        Storage.addResetToken user.id, token
        deferred.resolve(token)
      .fail ->
        deferred.reject 'err_bad_email'
    deferred.promise

module?.exports = Auth
