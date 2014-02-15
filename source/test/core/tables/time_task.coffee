  describe '#time_task', ->

    it 'should add timestamps to an existing task', (done) ->

      model =
        id: task.id
        listId: now
        name: now
        notes: now
        priority: now
        date: now
        completed: now

      db.time_task.create(model)
        .then -> done()
        .catch(log)

    it 'should read timestamps for an existing task', (done) ->

      db.time_task.read(task.id).then (times) ->
        times.should.eql
          id: task.id
          listId: now
          name: now
          notes: now
          priority: now
          date: now
          completed: now
        done()

    it 'should update timestamps for an existing task', (done) ->

      db.time_task.update(task.id, { listId: now })
      .then ->
        db.time_task.read(task.id, 'listId')
      .then (times) ->
        times.listId.should.equal now
        done()

    it 'should destroy timestamps for an existing task', (done) ->

      db.time_task.destroy(task.id)
      .then ->
        db.time_task.read(task.id)
      .catch (err) ->
        err.should.equal 'err_no_row'
        done()
