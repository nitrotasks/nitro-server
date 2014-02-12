Promise = require 'bluebird'
crypto  = require 'crypto'
bcrypt = require 'bcrypt'
Users   = require '../controllers/users'
Keys    = require '../utils/keychain'
db      = require '../controllers/query'

# -----------------------------------------------------------------------------
# Bcrypt
# -----------------------------------------------------------------------------

bcrypt =
  compare:  Promise.promisify(bcrypt.compare, bcrypt)
  hash:     Promise.promisify(bcrypt.hash, bcrypt)
  salt:     Promise.promisify(bcrypt.genSalt, bcrypt)


# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

RESET_TOKEN_LENGTH = 22
LOGIN_TOKEN_LENGTH = 64

ERR_BAD_PASS  = 'err_bad_pass'
ERR_BAD_EMAIL = 'err_bad_email'
ERR_BAD_NAME  = 'err_bad_name'


# -----------------------------------------------------------------------------
# Auth Controller
# -----------------------------------------------------------------------------

Auth =

  ###
   * Auth.hash
   *
   * Hash some data using bcrypt with a randomly generated salt.
   *
   * - data (string)
   * > hashed data (string)
  ###

  hash: (data) ->
    bcrypt.salt(10).then (salt) ->
      bcrypt.hash(data, salt)


  ###
   * Auth.compare
   *
   * Check to see if some data matches a hash.
   *
   * - data (string)
   * - hash (string)
   * > boolean
  ###

  compare: (data, hash) ->
    bcrypt.compare(data, hash)


  ###
   * Auth.randomBytes
   *
   * Generates secure random data.
   * Wrap crypto.randomBytes in a promise.
   *
   * - len (int) : number of bytes to get
   * > random data (buffer)
  ###

  randomBytes: Promise.promisify(crypto.randomBytes, crypto)


  ###
   * Auth.randomToken
   *
   * Generate a random string of a certain length.
   * It generates random bytes and then converts them to hexadecimal.
   * It generates more bytes then it needs and then trims the excess off.
   *
   * - len (int) : The length of the string
   * > random token (string)
  ###

  randomToken: (len) ->
    byteLen = Math.ceil(len / 2)
    Auth.randomBytes(byteLen).then (bytes) ->
      bytes.toString('hex')[0 ... len]


  ###
   * Generate a password reset token for a user
   *
   * - email (string) : the email of the user
   * > token
  ###

  # Generate a reset password token for the user
  createResetToken: (email) ->
    Promise.all([
      Auth.randomToken(RESET_TOKEN_LENGTH)
      Users.search(email)
    ]).spread (token, user) ->
      db.reset.create(user.id, token)


  ###
   * Create a login token for a user
   *
   * - id (int) : The user id
   * > token
  ####

  createLoginToken: (id) ->
    Auth.randomToken(LOGIN_TOKEN_LENGTH).then (token) ->
      db.login.create(id, token).return(token)

  returnLoginToken: (id) ->
    Auth.createLoginToken(id).then (token) ->
      return [id, token]


  ###
   * Generate a login token for a user
   * Only works if the email and password match
   *
   * - email (string)
   * - pass (string) : plaintext
   * > login_token
   * ! err_bad_pass
  ###

  # Gives the user a token to use to connect to SocketIO
  login: (email, pass) ->
    id = null
    Users.search(email).then (user) ->
      id = user.id
      user.getPassword()
    .then (password) ->
      Auth.compare(pass, password)
    .then (same) ->
      if not same then throw ERR_BAD_PASS
      Auth.returnLoginToken(id)
    .catch ->
      throw ERR_BAD_PASS


  ###
   * Register a user.
   * Hashes the users password and stores it in the database
   *
   * - name (string)
   * - email (string)
   * - pass (string) : plaintext
   * > login token
   * ! err_bad_name
   * ! err_bad_email
   * ! err_bad_pass
  ###

  register: (name, email , pass) ->

    # Validation

    if name.length is 0
      return Promise.reject(ERR_BAD_NAME)

    if email.length is 0
      return Promise.reject(ERR_BAD_EMAIL)

    if pass.length is 0
      return Promise.reject(ERR_BAD_PASS)

    # Hash password

    Auth.hash(pass).then (hash) ->
      Users.create
        name: name
        email: email
        password: hash

    # Return login token
    .then (user) ->
      Auth.returnLoginToken(user.id)

  ###
   * Change a users password
   *
   * - user (user) : the user instance
   * - pass (string) : plaintext
  ###

  changePassword: (user, pass) ->
    Auth.hash(pass).then (hash) ->
      user.setPassword hash


module.exports = Auth
