describe '#time_list', ->

  it 'should add timestamps to an existing list', (done) ->

    model =
      id: list.id
      name: now
      tasks: now

    db.time_list.create(model)
    .then -> done()
    .done()

  it 'should read timestamps for an existing list', (done) ->

    db.time_list.read(list.id)
    .then (times) ->
      times.should.eql
        id: list.id
        name: now
        tasks: now
    .then -> done()
    .done()

  it 'should update timestamps for an existing list', (done) ->

    db.time_list.update(list.id, { name: now })
    .then ->
      db.time_list.read(list.id, 'name')
    .then (times) ->
      times.name.should.equal now
    .then -> done()
    .done()

  it 'should destroy timestamps for an existing list', (done) ->

    db.time_list.destroy(list.id)
    .then ->
      db.time_list.read(list.id)
    .catch (err) ->
      err.should.equal 'err_no_row'
      done()