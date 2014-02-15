Promise = require('bluebird')
should  = require('should')
setup   = require('../setup')
db      = require('../../core/controllers/database')
Time    = require('../../core/models/time')

# Testing the database storage engine

describe 'Database', ->

  user =
    name: 'Jimmy'
    email: 'jimmy@gmail.com'
    password: 'blah'
    pro: 0

  list =
    userId: null
    name: 'List 1'

  task =
    userId: null
    listId: null
    name: 'Task 1'
    notes: 'Some notes'
    priority: 2
    date: 0
    completed: 0

  before setup

  now = null

  beforeEach ->
    now = Time.now()


