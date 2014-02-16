should   = require('should')
Promise  = require('bluebird')
crypto   = require('../../core/controllers/crypto')

describe 'Crypto', ->

  describe ':hash', ->

    it 'should hash some data', (done) ->

      string = 'hello world'

      crypto.hash(string)
      .then (hash) ->
        hash.should.have.length(60)
        crypto.compare(string, hash)
      .then (same) ->
        same.should.be.true
      .then -> done()
      .done()

  describe ':compare', ->

    it 'should compare correctly', (done) ->

      real = 'hamburger'
      fake = 'Hamburger'

      crypto.hash(real)
      .then (hash) ->
        crypto.compare(fake, hash)
      .then (same) ->
        same.should.be.false
      .then -> done()
      .done()

  describe ':fastHash', ->

    it 'should quickly hash data', (done) ->

      crypto.randomToken(64)
      .then (string) ->
        crypto.fastHash(string)
      .then -> done()
      .done()

  describe ':fastCompare', ->

    it 'should quickly compare data', (done) ->

      crypto.randomToken(64)
      .then (string) ->
        hash = crypto.fastHash(string)
        crypto.fastCompare(string, hash).should.equal(true)
      .then -> done()
      .done()

  describe ':randomBytes', ->

    it 'should generate random bytes', (done) ->

      size = 30

      crypto.randomBytes(size)
      .then (bytes) ->
        bytes.should.have.length(size)
      .then -> done()
      .done()

  describe ':randomToken', ->

    it 'should be the correct length', (done) ->

      sizes = (i for i in [0 .. 80])

      Promise.map sizes, (size) ->
        crypto.randomToken(size)

      .map (token, size) ->
        token.should.have.length(size)

      .then -> done()
      .done()
