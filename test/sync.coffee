assert = require "assert"
Sync   = require "../app/sync"
User   = require "../app/storage"

socket =
  emit: ->
  broadcast:
    to: ->
      emit: ->
  on: ->
  join: ->
sync = new Sync(socket)

data_user = no

describe "Sync ->", ->

  it "Login", (done) ->
    sync.login("stayradiated").then (user) ->
      assert.equal user.username, sync.user.username, "stayradiated"
      done()

  it "Login twice", (done) ->
    sync.login("stayradiated").then (user) ->
      data_user = user
      assert.equal user.username, sync.user.username, "stayradiated"
      done()

  it "Add task", ->
    sync.create ["Task", {name: "Task 1"}]
    sync.create ["Task", {name: "Task 2"}]
    sync.create ["Task", {name: "Task 3"}]
    # Check tasks exist
    tasks = data_user.data("Task")
    assert.equal tasks["0"].name, "Task 1"
    assert.equal tasks["1"].name, "Task 2"
    assert.equal tasks["2"].name, "Task 3"

  it "Add list", ->
    sync.create ["List", {name: "List 1"}]
    sync.create ["List", {name: "List 2"}]
    sync.create ["List", {name: "List 3"}]
    # Check lists exist
    lists = data_user.data("List")
    assert.equal lists["0"].name, "List 1"
    assert.equal lists["1"].name, "List 2"
    assert.equal lists["2"].name, "List 3"

  it "Update Task", ->
    sync.update ["Task", {id: "0", name: "Task 1 has been renamed"}]
    sync.update ["Task", {id: "1", name: "Task 2 has been renamed"}]
    sync.update ["Task", {id: "2", name: "Task 3 has been renamed"}]
    # Check names have been updated
    tasks = data_user.data("Task")
    assert.equal tasks["0"].name, "Task 1 has been renamed"
    assert.equal tasks["1"].name, "Task 2 has been renamed"
    assert.equal tasks["2"].name, "Task 3 has been renamed"

  it "Update List", ->
    sync.update ["List", {id: "0", name: "List 1 has been renamed"}]
    sync.update ["List", {id: "1", name: "List 2 has been renamed"}]
    sync.update ["List", {id: "2", name: "List 3 has been renamed"}]
    # Check names have been updated
    lists = data_user.data("List")
    assert.equal lists["0"].name, "List 1 has been renamed"
    assert.equal lists["1"].name, "List 2 has been renamed"
    assert.equal lists["2"].name, "List 3 has been renamed"

  it "Destroy Tasks", ->
    sync.destroy ["Task", "0"]
    sync.destroy ["Task", "1"]
    sync.destroy ["Task", "2"]
    # Check tasks have been deleted
    tasks = data_user.data("Task")
    assert.equal tasks["0"].hasOwnProperty("deleted"), yes
    assert.equal tasks["1"].hasOwnProperty("deleted"), yes
    assert.equal tasks["2"].hasOwnProperty("deleted"), yes

  it "Destroy Lists", ->
    sync.destroy ["List", "0"]
    sync.destroy ["List", "1"]
    sync.destroy ["List", "2"]
    # Check lists have been deleted
    lists = data_user.data("Task")
    assert.equal lists["0"].hasOwnProperty("deleted"), yes
    assert.equal lists["1"].hasOwnProperty("deleted"), yes
    assert.equal lists["2"].hasOwnProperty("deleted"), yes

  it "Logout", ->
    sync.logout()
