Q       = require 'kew'
bcrypt  = require 'bcrypt'
crypto  = require 'crypto'
Storage = require './storage'
oauth   = require './oauth'
Keys    = require './keychain'

# Wrap bcrypt in promises
bcrypt =
  compare:  Q.bindPromise bcrypt.compare,  bcrypt
  hash:     Q.bindPromise bcrypt.hash,     bcrypt
  salt:     Q.bindPromise bcrypt.genSalt,  bcrypt


RESET_TOKEN_LENGTH = 22
LOGIN_TOKEN_LENGTH = 64
REGISTRATION_TOKEN_LENGTH = 22

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
   * > encrypted data
  ###

  hash: (data) ->
    bcrypt.salt(10).then (salt) -> bcrypt.hash data, salt


  ###
   * Check a hash against some data
   *
   * - data (string)
   * - hash (buffer?)
  ###

  compare: (data, hash) ->
    deferred = Q.defer()
    bcrypt.compare data, hash, (err, same) ->
      if err then return deferred.reject()
      deferred.resolve same
    return deferred.promise

  # Wrap crypto.randomBytes in a promise
  randomBytes: Q.bindPromise crypto.randomBytes, crypto

  ###
   * Generate a random string of a certain length
   *
   * - len (int) : The length of the string
  ###

  createToken: (len) ->
    byteLen = Math.ceil len * 0.75
    Auth.randomBytes(byteLen).then (bytes) ->
      return bytes.toString('base64')[0...len]

  ###
   * Create a login token for a user
   *
   * - id (int) : The user id
   * > token
  ####

  createLoginToken: (id) ->
    Auth.createToken(LOGIN_TOKEN_LENGTH).then (token) ->
      Storage.addLoginToken id, token


  ###
   * Generate a login token for a user
   * Only works if the email and password match
   *
   * - email (string)
   * - pass (string) : plaintext
   * > token
  ###

  # Gives the user a token to use to connect to SocketIO
  login: (email, pass) ->
    Storage.getByEmail(email).then (user) ->
      Auth.compare(pass, user.password).then (same) ->
        if not same then throw 'err_bad_pass'
        Auth.createLoginToken user.id


  ###
   * Register a user.
   * Hashes the users password and stores it in the database
   *
   * - name (string)
   * - email (string)
   * - pass (string) : plaintext
   * > registration token
   * ! invalid details
  ###

  register: (name, email, pass) ->

    # Validation

    if name.length is 0
      return Q.reject 'err_bad_name'

    if email.length is 0
      return Q.reject 'err_bad_email'

    if pass.length is 0
      return Q.reject 'err_bad_pass'

    # Hash password

    Q.all([
      Auth.createToken REGISTRATION_TOKEN_LENGTH
      Auth.hash pass
    ]).then ([token, hash]) ->
      Storage.register token, name, email, hash


  ###
   * Verify a registration using a token.
   * Should be used to verify that the user owns the email address.
   *
   * - token (string) : the registration token
   * > user info stored at registration
  ###

  verifyRegistration: (token) ->
    Storage.getRegistration(token).then (user) ->
      Storage.add
        name: user.name
        email: user.email
        password: user.password


  ###
   * Generate a password reset token for a user
   *
   * - email (string) : the email of the user
   * > token
  ###

  # Generate a reset password token for the user
  createResetToken: (email) ->
    Q.all([
      Auth.createToken RESET_TOKEN_LENGTH
      Storage.getByEmail email
    ]).then ([token, user]) ->
      Storage.addResetToken user.id, token


module.exports = Auth
