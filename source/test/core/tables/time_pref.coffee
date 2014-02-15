
  describe '#time_pref', ->

    before (done) ->
      db.pref.create
        userId: user.id
      .then -> done()
      .done()

    it 'should add timestamps to an existing pref', (done) ->

      model =
        id: user.id
        sort: now
        night: now
        language: now
        weekStart: now
        dateFormat: now
        confirmDelete: now
        moveCompleted: now

      db.time_pref.create(model).then -> done()

    it 'should read timestamps for an existing pref', (done) ->

      db.time_pref.read(user.id).then (times) ->
        times.should.eql
          id: user.id
          sort: now
          night: now
          language: now
          weekStart: now
          dateFormat: now
          confirmDelete: now
          moveCompleted: now
        done()

    it 'should update timestamps for an existing pref', (done) ->

      db.time_pref.update(user.id, { sort: now })
      .then ->
        db.time_pref.read(user.id, 'sort')
      .then (times) ->
        times.sort.should.equal now
        done()

    it 'should destroy timestamps for an existing pref', (done) ->

      db.time_pref.destroy(user.id)
      .then ->
        db.time_pref.read(user.id)
      .catch (err) ->
        err.should.equal 'err_no_row'
        done()