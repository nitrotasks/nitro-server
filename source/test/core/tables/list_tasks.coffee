  describe '#list_tasks', ->

    it 'should add a task to a list', (done) ->

      db.list_tasks.create(list.id, task.id).then -> done()

    it 'should read all tasks from a list', (done) ->

      db.list_tasks.read(list.id).then (tasks) ->
        tasks.should.eql [ task.id ]
        done()

    it 'should remove a task from a list', (done) ->

      db.list_tasks.destroy(list.id, task.id).then -> done()

    it 'should return an empty array when there are no tasks', (done) ->

      db.list_tasks.read(list.id).then (tasks) ->
        tasks.should.eql []
        done()

    it 'should add the same task to the same list again', (done) ->

      db.list_tasks.create(list.id, task.id).then -> done()

    it 'should remove all tasks from a list', (done) ->

      db.list_tasks.destroyAll(list.id)
        .then ->
          db.list_tasks.read(list.id)
        .then (tasks) ->
          tasks.should.eql []
          done()
