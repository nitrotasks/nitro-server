assert = require "assert"
User = require "../app/storage"
Q = require "q"

users = [
  ["stayradiated", "george@czabania.com", "password"]
  ["consindo", "jono@jonocooper.com", "another password"]
  ["teqnoqolor", "dev@stayradiated.com", "drowssap"]
]

describe "Storage ->", ->

  it "Add users", (done) ->
    users.forEach (user, i, array) ->
      User.add(user[0], user[1], user[2]).then (data) ->
        assert.equal data.username, user[0]
        assert.equal data.email, user[1]
        assert.equal data.password, user[2]
        if i is array.length - 1
          done()

  it "Get users by name", (done) ->
    users.forEach (user, i, array) ->
      User.getByName(user[0]).then( (data) ->
        assert.equal user[0], data.username
        array[i][3] = data.id
        if i is array.length - 1 then done()
      ).fail (err) ->
        console.log err
        done()

  it "Get users by email", (done) ->
    users.forEach (user, i, array) ->
      User.getByEmail(user[1]).then (data) ->
        assert.equal user[1], data.email
        if i is array.length - 1 then done()


  it "Change password", (done) ->
    Q.spread [
        User.get(users[0][3])
        User.get(users[0][3])
    ], (u1, u2) ->
      u1.changePassword("my-new-password").then ->
        assert.equal "my-new-password", u1.password, u2.password
        done()

  it "Change Email", (done) ->
    newEmail = users[1][1] = "example@mail.com"
    Q.spread [
      User.get(users[1][3])
      User.get(users[1][3])
    ], (u1, u2) ->
      u1.changeEmail(newEmail).then( ->
        assert.equal newEmail, u1.email, u2.email
      ).then( ->
        User.getByEmail(newEmail)
      ).then (u3) ->
        assert.equal u3.username, users[1][0]
        done()

  it "Change Pro Status", (done) ->
    hasPro = "1"
    Q.spread [
      User.get(users[2][3])
      User.get(users[2][3])
    ], (u1, u2) ->
      u2.changeProStatus(hasPro).then ->
        assert.equal hasPro, u1.has_pro, u2.has_pro
        done()

  it "Save Data", (done) ->
    fakeData =
      a_string: "Just some random data"
      a_number: 1234
      a_boolean: true
      an_array: ["word", 12, false]
      an_object:
        neat: "yep"
        awesome: "nope"
    Q.spread [
      User.get(users[1][3])
      User.get(users[1][3])
    ], (u1, u2) ->
      u1.data("Fake", fakeData)
      u1.save("Fake").then ->
        assert.equal fakeData, u1.data("Fake"), u2.data("Fake")
        done()

  it "Data Index", (done) ->
    User.get(users[1][3]).then (user) ->
      index = user.index "Fake"
      Q.fcall( ->
        user.incrIndex("Fake")
      ).then( ->
        assert.equal ++index, user.index "Fake"
        user.incrIndex("Fake")
      ).then( ->
        assert.equal ++index, user.index "Fake"
        done()
      )

  it "Release users", (done) ->
    assert.notEqual User.records[users[2][3]], undefined
    User.release users[2][3]
    assert.equal User.records[users[2][3]], undefined
    done()

  it "Remove users", (done) ->
    users.forEach (user, i, array) ->
      User.remove(user[3]).then( ->
        User.get(user[3])
      ).fail ->
        if i is  array.length - 1
          done()
