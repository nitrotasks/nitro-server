# Crypto.coffee
# Handles all the cryptography code

Promise    = require('bluebird')
base64     = require('urlsafe-base64')
nodeCrypto = require('crypto')
bcrypt     = Promise.promisifyAll(require('bcrypt'))

# - hash
# - compare hash
# - random bytes
# - random tokens
# - reset tokens
# - login tokens

crypto =

  ###
   * crypto.hash
   *
   * Hash some data using bcrypt with a randomly generated salt.
   * salt:rounds = 10
   *
   * - data (string)
   * > promise > hashed data (string)
  ###

  hash: (data) ->
    bcrypt.hashAsync(data, 10)


  ###
   * crypto.compare
   *
   * Check to see if some data matches a hash.
   *
   * - data (string)
   * - hash (string)
   * > promise > boolean
  ###

  compare: (data, hash) ->
    bcrypt.compareAsync(data, hash)


  ###
   * crypto.fastHash
   *
   * Quickly hash some data.
   * Used to protect random tokens
   *
   * - data (string) : plaintext
   * > string : url safe base64 encoded
  ###


  sha256: (data) ->
    buffer = nodeCrypto.createHash('sha256')
      .update(data, 'utf-8')
      .digest()
    base64.encode(buffer)


module.exports = crypto
