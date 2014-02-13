require('should')
setup = require('../../setup')
List  = require('../../../core/models/list')

describe 'List', ->

  before (done) ->
    setup()
    .then(setup.createUser)
    .then(setup.createList)
    .then(setup.createTask)
    .return()
    .then(done)

  describe ':all', ->

    it 'should get all users lists', (done) ->

      list = new List(1)
      list.all().then (lists) ->
        lists.should.eql [
          id: 1
          userId: 1
          name: 'list_name'
          tasks: [ 1 ]
        ]
      .return().then(done).done()
