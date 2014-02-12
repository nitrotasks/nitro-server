should   = require 'should'
setup    = require './setup'
Users    = require '../app/controllers/users'
time     = require '../app/utils/time'
Log = require '../app/utils/log'

log = Log 'users - test'

users = [
  {name: 'stayradiated',  email: 'george@czabania.com',   password: 'abc',     pro: 0}
  {name: 'consindo',      email: 'jono@jonocooper.com',   password: 'xkcd',    pro: 0}
  {name: 'nitroman',      email: 'user@nitrotaks.com',    password: 'hunter2', pro: 0}
]

describe 'Users API >', ->

  before setup

# -----------------------------------------------------------------------------
# Adding Users
# -----------------------------------------------------------------------------

  describe '#create', ->

    it 'should be able to add users', (done) ->
      users.forEach (user, i, array) ->
        Users.create(user)
          .then (user) ->
            user.id.should.be.a.Number
            # Save user ID so we can use it future tests
            users[i].id = user.id
            if i is array.length - 1 then done()

    it 'should not allow duplicate email addresses', (done) ->
      users.forEach (user, i, array) ->
        Users.create(user).catch (err) ->
          err.should.equal 'err_old_email'
          if i is array.length - 1 then done()


# -----------------------------------------------------------------------------
# Checking Existing Users
# -----------------------------------------------------------------------------

  describe '#exists', ->

    it 'should return false if an email doesn\'t exist', (done) ->

      Users.exists('joe@smith.com')
        .then (exists) ->
          exists.should.be.false
          done()


    it 'should return true if an email exists', (done) ->

      users.forEach (user, i, array) ->
        Users.exists(user.email).then (exists) ->
          exists.should.be.true
          if i is array.length - 1 then done()


# -----------------------------------------------------------------------------
# Searching Users
# -----------------------------------------------------------------------------

  describe '#search', ->

    it 'should get users by email', (done) ->

      users.forEach (data, i, array) ->
        Users.search(data.email).then (user) ->

          user.info().then (info) ->
            info.should.eql
              name: data.name
              email: data.email
              pro: 0
            if i is array.length - 1 then done()


    it 'should fail if you try and get a non-existant user by email', (done) ->

      Users.search('john@example.com').catch (err) ->
        err.should.equal 'err_no_user'
        done()


# -----------------------------------------------------------------------------
# Reading Users
# -----------------------------------------------------------------------------

  describe '#read', ->

    it 'should get users by id', (done) ->

      users.forEach (data, i, array) ->
        Users.read(data.id).then (user) ->
          user.info().then (info) ->
            info.should.eql
              name: data.name
              email: data.email
              pro: 0
            if i is array.length - 1 then done()


    it 'should fail when user does not exist', (done) ->

      Users.read(300).catch (err) ->
        err.should.equal 'err_no_user'
        done()


# -----------------------------------------------------------------------------
# Destroying Users
# -----------------------------------------------------------------------------

  describe '#destroy', ->

    it 'should be able to delete users from disk', (done) ->

      users.forEach (user, i, array) ->
        Users.destroy(user.id).then ->
          if i is array.length - 1 then done()

    it 'should not be able to find deleted users', (done) ->

      users.forEach (user, i, array) ->
        Users.read(user.id).catch ->
          if i is array.length - 1 then done()

