  describe '#reset', ->

    token = null

    reset =
      id: null
      token: 'actually'

    before ->
      reset.id = user.id

    it 'should create a reset token' , (done) ->

      db.reset.create(reset.id, reset.token).then (_token) ->
        token = _token
        token.should.match /^\d+_\w+$/
        done()

    it 'should read a reset token', (done) ->

      db.reset.read(token).then (id) ->
        id.should.equal reset.id
        done()

    it 'should throw err when using an invalid token', (done) ->

      db.reset.read('blah').catch (err) ->
        err.should.equal 'err_bad_token'
        done()

    it 'should destroy a reset token', (done) ->

      db.reset.destroy(token).then -> done()

    it 'should throw err when reading a token that does not exist', (done) ->

      db.reset.read(token).catch (err) ->
        err.should.equal 'err_bad_token'
        done()
