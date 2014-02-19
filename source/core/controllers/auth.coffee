Promise = require('bluebird')
crypto  = require('../controllers/crypto')
db      = require('../controllers/database')
Users   = require('../models/user')

ERR_BAD_PASS  = 'err_bad_pass'
ERR_BAD_EMAIL = 'err_bad_email'
ERR_BAD_NAME  = 'err_bad_name'

# -----------------------------------------------------------------------------
# Auth Controller
# -----------------------------------------------------------------------------

auth =

  ###
   * Generate a login token for a user
   * Only works if the email and password match
   *
   * - email (string)
   * - pass (string) : plaintext
   * > user id
   * ! err_bad_pass
  ###

  # Gives the user a token to use to connect to SocketIO
  login: (email, pass) ->

    email = email.toLowerCase()

    if email.length is 0
      return Promise.reject(new Error(ERR_BAD_EMAIL))
    
    if pass.length is 0
      return Promise.reject(new Error(ERR_BAD_PASS))

    id = null
    Users.search(email).then (user) ->
      id = user.id
      user.read('password').get('password')
    .then (hash) ->
      crypto.compare(pass, hash)
    .then (same) ->
      if not same then throw new Error(ERR_BAD_PASS)
      return id


  ###
   * Register a user.
   * Hashes the users password and stores it in the database
   *
   * - name (string)
   * - email (string)
   * - pass (string) : plaintext
   * > user id
   * ! err_bad_name
   * ! err_bad_email
   * ! err_bad_pass
  ###

  register: (name, email , pass) ->

    email = email.toLowerCase()

    # Validation

    if name.length is 0
      return Promise.reject(new Error(ERR_BAD_NAME))

    if email.length is 0
      return Promise.reject(new Error(ERR_BAD_EMAIL))

    if pass.length is 0
      return Promise.reject(new Error(ERR_BAD_PASS))

    # Hash password

    crypto.hash(pass)
    .then (hash) ->

      Users.create
        name: name
        email: email
        password: hash

    # Return login token
    .then (user) ->
      return user.id

  ###
   * Change a users password
   *
   * - user (user) : the user instance
   * - pass (string) : plaintext
  ###

  changePassword: (user, pass) ->
    crypto.hash(pass).then (password) ->
      user.update { password }

module.exports = auth
