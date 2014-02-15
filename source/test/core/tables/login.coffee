  describe '#login', ->

    login =
      id: null
      token: 'battery-horse-staple'

    before ->
      login.id = user.id

    it 'should create a new entry', (done) ->

      db.login.create(login.id, login.token).then -> done()

    it 'should read the date the login token was created', (done) ->

      db.login.read(login.id, login.token, 'created_at').then (info) ->
        login.created_at = info.created_at
        login.created_at.should.be.an.instanceOf Date
        done()

    it 'should read an existing entry', (done) ->

      db.login.read(login.id, login.token).then (info) ->
        info.should.eql
          userId: login.id
          token: login.token
          created_at: login.created_at
        done()

    it 'should check if a login exists', (done) ->

      db.login.exists(login.id, login.token).then (exists) ->
        exists.should.equal true
        done()

    it 'should destroy an existing entry', (done) ->

      db.login.destroy(login.id, login.token).then -> done()

    it 'should check if a login does not exist', (done) ->

      db.login.exists(login.id, login.token).then (exists) ->
        exists.should.equal false
        done()

    it 'should throw err when reading an entry that does not exist', (done) ->

      db.login.read(login.id, login.token).catch (err) ->
        err.should.equal 'err_no_row'
        done()

    it 'should create another login token', (done) ->

      db.login.create(login.id, login.token)
      .then ->
        db.login.create(login.id, 'temp')
      .then ->
        db.login.create(login.id, 'orary')
      .then ->
        done()

    it 'should delete all login token', (done) ->

      promise = Promise.all [
        db.login.exists login.id, login.token
        db.login.exists user.id, 'temp'
        db.login.exists user.id, 'orary'
      ]

      promise.spread (a, b, c)->

        a.should.equal true
        b.should.equal true
        c.should.equal true

        db.login.destroyAll(user.id)

      .then ->

        Promise.all [
          db.login.exists login.id, login.token
          db.login.exists user.id, 'temp'
          db.login.exists user.id, 'orary'
        ]

      .spread (a, b, c) ->

        a.should.equal false
        b.should.equal false
        c.should.equal false

        done()

      .catch(log)