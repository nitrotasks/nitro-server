  describe '#user', ->

    it 'should create a new user', (done) ->

      db.user.create(user)
      .then (id) ->
        id.should.be.a.Number
        user.id = id
      .then -> done()
      .done()

    it 'should check if user exists', (done) ->

      db.user.exists(user.id).then (exists) ->
        exists.should.equal true
      .then -> done()
      .done()

    it 'should store the creation time', (done) ->

      db.user.read(user.id, 'created_at').then (info) ->
        info.created_at.should.be.an.instanceOf Date
        user.created_at = info.created_at
      .then -> done()
      .done()

    it 'should fetch all user information', (done) ->

      db.user.read(user.id).then (info) ->
        info.should.eql user
      .then -> done()
      .done()

    it 'should update an existing user', (done) ->

      user.name = 'James'
      model = name: user.name
      db.user.update(user.id, model)
      .then -> done()
      .done()

    it 'should fetch a updated information', (done) ->

      db.user.read(user.id, 'name')
      .then (info) ->
        info.name.should.equal user.name
      .then -> done()
      .done()

    it 'should fetch multiple values', (done) ->

      db.user.read(user.id, ['name', 'email'])
      .then (info) ->
        info.should.eql
          name: user.name
          email: user.email
      .then -> done()
      .done()

    it 'should delete an existing user', (done) ->

      db.user.destroy(user.id)
      .then -> done()
      .done()

    it 'should check if a user does not exist', (done) ->

      db.user.exists(user.id)
      .then (exists) ->
        exists.should.equal false
      .then -> done()
      .done()

    it 'should throw err when fetching a user that does not exist', (done) ->

      db.user.read(user.id, 'name')
      .catch (err) ->
        err.message.should.equal 'err_no_row'
        done()
      .done()

    it 'should throw err when updating a user that does not exist', (done) ->

      model = email: 'james@gmail.com'
      db.user.update(user.id, model).catch (err) ->
        err.message.should.equal 'err_no_row'
        done()
      .done()

    it 'should not throw err when destroying a user that does not exist', (done) ->

      db.user.destroy(user.id)
      .then -> done()
      .done()

    it 'should create another user', (done) ->

      delete user.id
      delete user.created_at

      db.user.create(user)
      .then (id) ->
        user.id = id
      .then -> done()
      .done()

