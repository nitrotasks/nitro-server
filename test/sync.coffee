assert = require "assert"
Sync = require "../app/sync"

socket =
  emit: ->
  broadcast:
    to: ->
      emit: ->
  on: ->
  join: ->
sync = new Sync(socket)

describe "Sync ->", ->

  it "Login", (done) ->
    sync.login "stayradiated", ->
      assert.equal sync.user.username, "stayradiated"
      done()

  it "Add task", (done) ->
    sync.create ["Task", {name: "Task 1"}]
    sync.create ["Task", {name: "Task 2"}]
    sync.create ["Task", {name: "Task 3"}]
    done()

  it "Add list", (done) ->
    sync.create ["List", {name: "List 1"}]
    sync.create ["List", {name: "List 2"}]
    sync.create ["List", {name: "List 3"}]
    done()

  it "Update Task", (done) ->
    sync.update ["Task", {id: "0", name: "A different name"}]
    done()

  it "Logout", (done) ->
    sync.logout()
    done()
