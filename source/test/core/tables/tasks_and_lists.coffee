
  describe '#task_and_lists', ->

    it 'should require tasks to have a list', (done) ->

      model =
        userId: user.id
        listId: 2000
        name: 'Task 2'

      db.task.create(model).catch -> done()

    it 'deleting a task should remove it from a list', (done) ->

      task =
        userId: user.id
        listId: list.id
        name: 'Task 3'

      # Create a new task
      db.task.create(task)
      .then (id) ->
        task.id = id

      # Add the task to the list
        db.list_tasks.create(list.id, task.id)
      .then ->

      # Check that we have added the task
        db.list_tasks.read(list.id)
      .then (tasks) ->
        tasks.should.eql [ task.id ]

      # Destroy the task
        db.task.destroy(task.id)
      .then ->

      # Check that the task is no longer in the list
        db.list_tasks.read(list.id)
      .then (tasks) ->
        tasks.should.eql []
        done()

      .catch(log)