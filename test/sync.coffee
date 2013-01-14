assert = require "assert"
Sync   = require "../app/sync"
Auth   = require "../app/auth"

socket =
  emit: ->
  broadcast:
    to: ->
      emit: ->
  on: ->
  join: ->

# Create a new user using the Auth API
describe "Auth API", ->

sync = no

describe "Sync API", ->

  it "should create a new user", (done) ->
    Auth.register("George", "mail@example.com", "password").then ->
      done()

  it "should login", (done) ->
    sync = new Sync(socket, 1)
    done()

  it "should login twice", (done) ->
    sync.login(1).then ->
      assert.equal sync.user.name, "George"
      done()

  it "should add lists", ->
    sync.create ["List", name: "List 1", tasks: []]
    sync.create ["List", name: "List 2", tasks: []]
    sync.create ["List", name: "List 3", tasks: []]
    # Check lists exist
    lists = sync.user.data("List")
    assert.equal lists["s-0"].name, "List 1"
    assert.equal lists["s-1"].name, "List 2"
    assert.equal lists["s-2"].name, "List 3"

  it "should add tasks", ->
    sync.create ["Task", name: "Task 1", list: "s-0"]
    sync.create ["Task", name: "Task 2", list: "s-0"]
    sync.create ["Task", name: "Task 3", list: "s-0"]
    # Check tasks exist
    tasks = sync.user.data("Task")
    lists = sync.user.data("List")
    assert.equal tasks["s-0"].name, "Task 1"
    assert.equal tasks["s-1"].name, "Task 2"
    assert.equal tasks["s-2"].name, "Task 3"
    assert.deepEqual lists["s-0"].tasks, ["s-0", "s-1", "s-2"], "Tasks have been added to the list"

  it "Find model", ->
    # Should find tasks
    task = sync.findModel("Task", "s-0")
    assert.equal task.name, "Task 1"
    # Should find lists
    list = sync.findModel("List", "s-2")
    assert.equal list.name, "List 3"
    # Missing items should return new objects
    no_model = sync.findModel("Task", "s-100")
    no_class = sync.hasModel("Empty", "s-2")
    assert.deepEqual no_model, {}

  it "Get array", ->
    tasks = sync.exportModel("Task")
    lists = sync.exportModel("List")
    empty = sync.exportModel("Empty")
    # Should return an array
    assert.equal Array.isArray(tasks), yes
    # Should return our tasks and lists
    assert.equal tasks[0].name, "Task 1"
    assert.equal lists[2].name, "List 3"
    # If the class doesn't exist, it should return an empty array
    # BTW ([] == []) === false
    assert.equal Array.isArray(empty), yes
    assert.equal empty.length, 0

  it "Timestamps", ->
    now = Date.now()

    # Setting and getting
    sync.setTime "Task", "s-0", "name", now
    time = sync.getTime "Task", "s-0", "name"
    assert.equal now, time

    # Setting all timestamps
    sync.setTime "Task", "s-1", "all", now
    time = sync.getTime "Task", "s-1", "name"
    assert.equal now, time

    # Setting a group of timestamps
    times =
      name: now
      date: now + 10
      priority: now - 10
      notes: now + 20
    sync.setTime "Task", "s-2", times
    time = sync.getTime "Task", "s-2", "notes"
    assert.equal time, times.notes
    time = sync.getTime "Task", "s-2", "date"
    assert.equal time, times.date

    # Should return undefined on non-existing items
    no_key = sync.getTime "Task", "s-0", "missing"
    no_id  = sync.getTime "Task", "s-100", "name"
    no_class = sync.getTime "missing", "s-100", "name"
    assert.equal no_key, undefined
    assert.equal no_id, undefined
    assert.equal no_class, undefined

    # Clearing timestamps
    sync.clearTime "Task", "s-2"
    model = sync.user.data("Time")["Task"]["s-2"]
    assert.equal model, undefined

  it "Update Task", ->
    sync.update ["Task", {id: "s-0", name: "Task 1 has been renamed"}]
    sync.update ["Task", {id: "s-1", name: "Task 2 has been renamed"}]
    sync.update ["Task", {id: "s-2", name: "Task 3 has been renamed"}]
    # Check names have been updated
    tasks = sync.user.data("Task")
    assert.equal tasks["s-0"].name, "Task 1 has been renamed"
    assert.equal tasks["s-1"].name, "Task 2 has been renamed"
    assert.equal tasks["s-2"].name, "Task 3 has been renamed"

  it "Update List", ->
    sync.update ["List", {id: "s-0", name: "List 1 has been renamed"}]
    sync.update ["List", {id: "s-1", name: "List 2 has been renamed"}]
    sync.update ["List", {id: "s-2", name: "List 3 has been renamed"}]
    # Check names have been updated
    lists = sync.user.data("List")
    assert.equal lists["s-0"].name, "List 1 has been renamed"
    assert.equal lists["s-1"].name, "List 2 has been renamed"
    assert.equal lists["s-2"].name, "List 3 has been renamed"

  it "Destroy Tasks", ->
    sync.destroy ["Task", "s-0"]
    sync.destroy ["Task", "s-1"]
    sync.destroy ["Task", "s-2"]
    # Check tasks have been deleted
    tasks = sync.user.data("Task")
    assert.equal tasks["s-0"].hasOwnProperty("deleted"), yes
    assert.equal tasks["s-1"].hasOwnProperty("deleted"), yes
    assert.equal tasks["s-2"].hasOwnProperty("deleted"), yes

  it "Destroy Lists", ->
    sync.destroy ["List", "s-0"]
    sync.destroy ["List", "s-1"]
    sync.destroy ["List", "s-2"]
    # Check lists have been deleted
    lists = sync.user.data("Task")
    assert.equal lists["s-0"].hasOwnProperty("deleted"), yes
    assert.equal lists["s-1"].hasOwnProperty("deleted"), yes
    assert.equal lists["s-2"].hasOwnProperty("deleted"), yes

  it "Logout", ->
    sync.logout()
