throttle = require '../app/throttle'
assert = require 'assert'

describe 'throttle', ->

  it 'should throttle', (done) ->

    duration = 80
    interval = 20
    last = -Infinity
    count = 0

    fn = (args) ->

      now = Date.now()
      diff = now - last
      last = now

      if diff isnt Infinity
        assert diff >= duration
        assert diff <= duration + 5

      switch count++

        when 0
          assert.deepEqual args, [0]

        when 1
          assert.deepEqual args, [1,2,3]

        when 2
          assert.deepEqual args, [4, 5,6,7]

        when 3
          assert.deepEqual args, [8, 9,10,11]

        when 4
          assert.deepEqual args, [12, 13,14]
          done()

    fn = throttle fn, duration

    i = 0

    callFn = ->
      fn i++
      if i < 15
        setTimeout callFn, interval

    callFn()



