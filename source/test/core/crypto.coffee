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

  describe ':sha256', ->

    it 'should quickly hash data', ->

      string = 'some_random_string_that_is_rather_long'
      expectedHash = 'HYiBIqGYFV9YyIwWYTH1qea2hX9EaZML3K6akqIo6iE'
      crypto.sha256(string).should.equal(expectedHash)

    it 'should hash strings as utf-8', ->

      string = '0xdeadbeef'
      hash = crypto.sha256(string)
      hash.should.equal('QUJxC5tMqusAC45d4nG766x_UJqrL15h0e0ZWL_m1YM')

