  describe '#task', ->

    before ->
      task.userId = user.id
      task.listId = list.id

    it 'should create a new task', (done) ->

      db.task.create(task).then (id) ->
        task.id = id
        done()

    it 'should read an existing task', (done) ->

      db.task.read(task.id).then (info) ->
        task.should.eql info
        done()

    it 'should update an existing task', (done) ->

      task.name = 'Task 1 - Updated'
      model = name: task.name
      db.task.update(task.id, model).then -> done()

    it 'should read an updated task', (done) ->

      db.task.read(task.id, 'name').then (info) ->
        info.name.should.equal task.name
        done()

    it 'should destroy an existing task', (done) ->

      db.task.destroy(task.id).then -> done()

    it 'should create another task', (done) ->

      delete task.id
      db.task.create(task).then (id) ->
        task.id = id
        done()
