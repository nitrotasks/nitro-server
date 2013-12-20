Q       = require 'kew'
bcrypt  = require 'bcrypt'
crypto  = require 'crypto'
Storage = require '../controllers/storage'
Keys    = require '../utils/keychain'


# -----------------------------------------------------------------------------
# Bcrypt
# -----------------------------------------------------------------------------

bcrypt =
  compare:  Q.bindPromise bcrypt.compare,  bcrypt
  hash:     Q.bindPromise bcrypt.hash,     bcrypt
  salt:     Q.bindPromise bcrypt.genSalt,  bcrypt


# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

RESET_TOKEN_LENGTH        = 22
LOGIN_TOKEN_LENGTH        = 64
REGISTRATION_TOKEN_LENGTH = 22

ERR_BAD_PASS  = 'err_bad_pass'
ERR_BAD_EMAIL = 'err_bad_email'
ERR_BAD_NAME  = 'err_bad_name'


# -----------------------------------------------------------------------------
# Auth Controller
# -----------------------------------------------------------------------------

Auth =

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
    bcrypt.compare data, hash


  ###
   * Wrap crypto.randomBytes in a promise
   *
   * - len (int) : number of bytes to get
   * > buffer
  ###

  randomBytes: Q.bindPromise crypto.randomBytes, crypto


  ###
   * Generate a random string of a certain length.
   * We generate a bunch of random bytes and then covert them to base64.
   * We make sure to generate more bytes then we need and then cut
   * the excess off. This way we don't get any of the base64 padding.
   *
   * - len (int) : The length of the string
  ###

  createToken: (len) ->
    byteLen = Math.ceil len * 0.75
    Auth.randomBytes(byteLen).then (bytes) ->
      return bytes.toString('base64')[0...len]


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
   * ! err_bad_pass
  ###

  # Gives the user a token to use to connect to SocketIO
  login: (email, pass) ->
    user = null
    Storage.getByEmail(email).then (_user) ->
      user = _user
      Auth.compare(pass, user.password)
    .then (same) ->
      if not same then throw ERR_BAD_PASS
      Auth.createLoginToken user.id


  ###
   * Register a user.
   * Hashes the users password and stores it in the database
   *
   * - name (string)
   * - email (string)
   * - pass (string) : plaintext
   * > registration token
   * ! err_bad_name
   * ! err_bad_email
   * ! err_bad_pass
  ###

  register: (name, email, pass) ->

    # Validation

    if name.length is 0
      return Q.reject ERR_BAD_NAME

    if email.length is 0
      return Q.reject ERR_BAD_EMAIL

    if pass.length is 0
      return Q.reject ERR_BAD_PASS

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


module.exports = Auth
