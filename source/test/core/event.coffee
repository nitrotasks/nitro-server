should = require('should')
setup  = require('../setup')
event  = require('../../core/controllers/event')

describe 'event', ->

  client = null
  onMessage = null

  before (done) ->
    setup()
    .then ->
      event.listen (message) -> onMessage(message)
    .then -> done()
    .done()

  describe ':emit', (done) ->

    it 'should emit a message', (done) ->

      @timeout 10000

      data =
        sender: 'rails'
        user: 3
        event: 'user.update'
        args: [{ name: 'george' }]

      event.emit(data)

      onMessage = (message) ->
        message.should.eql(data)
        done()
