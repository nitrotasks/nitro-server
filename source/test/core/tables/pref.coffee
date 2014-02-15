
  describe '#pref', ->

    pref =
      userId: null
      sort: 0
      night: 0
      language: 'en-NZ'
      weekStart: 1
      dateFormat: 'dd/mm/yy'
      confirmDelete: 1
      moveCompleted: 1

    before ->
      pref.userId = user.id

    it 'should create a new pref', (done) ->

      db.pref.create(pref).then -> done()

    it 'should only allow one pref per user', (done) ->

      db.pref.create(pref).catch -> done()

    it 'should update a pref', (done) ->

      pref.sort = 1
      changes = sort: pref.sort

      db.pref.update(user.id, changes).then ->
        done()

    it 'should read from a pref', (done) ->

      db.pref.read(user.id)
      .then (info) ->
        info.should.eql pref
        done()
      .catch(log)

    it 'should destroy a pref', (done) ->

      db.pref.destroy(user.id).then ->
        done()
