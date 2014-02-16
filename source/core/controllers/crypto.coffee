# Crypto.coffee
# Handles all the cryptography code

Promise    = require('bluebird')
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
   *
   * salt:rounds = 10
   *
   * - data (string)
   * > hashed data (string)
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
   * > boolean
  ###

  compare: (data, hash) ->
    bcrypt.compareAsync(data, hash)


  fastHash: (data) ->
    nodeCrypto.createHash('sha256')
    .update(data)
    .digest('base64')

  fastCompare: (data, hash) ->
    crypto.fastHash(data) is hash


  ###
   * crypto.randomBytes
   *
   * Generates secure random data.
   * Wrap crypto.randomBytes in a promise.
   *
   * - len (int) : number of bytes to get
   * > random data (buffer)
  ###

  randomBytes: Promise.promisify(nodeCrypto.randomBytes, crypto)


  ###
   * crypto.randomToken
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
    crypto.randomBytes(byteLen).then (bytes) ->
      bytes.toString('hex')[0 ... len]

module.exports = crypto
