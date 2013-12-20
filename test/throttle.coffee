Q        = require 'kew'
assert   = require 'assert'
throttle = require '../app/utils/throttle'

assertNear = (a, b) ->
  assert a >= b
  assert b <= b + 7

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
        assertNear diff, duration

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


  it 'should handle multiple arguments', (done) ->

    count = 0

    fn = (args) ->

      switch count++

        when 0
          assert.deepEqual args, ['a', 'b', 'c']

        when 1
          assert.deepEqual args, ['d', 'e', 'f']
          done()

    fn = throttle fn, 200

    fn 'a', 'b', 'c'
    fn 'd', 'e'
    fn 'e', 'f'


  it 'should return promises', (done) ->

    duration = 500
    start = Date.now()
    count = 0

    fn = (args) ->

      diff = Date.now() - start

      switch count++

        when 0
          assertNear diff, 0
          assert.deepEqual args, ['a']

        when 1
          assertNear diff, duration
          assert.deepEqual args, ['b']

    fn = throttle fn, duration

    promise = Q.all [
      fn 'a'
      fn 'b'
    ]

    promise.then ->
      assertNear Date.now() - start, duration
      done()


  it 'should just work properly', (done) ->

    multiply = (i) -> i * 100
    duration = multiply 3


    tests = [

      input:  [0,1,2,3,4,5,6,7,9,10]
      output: [0,3,6,9,12]

    ,

      input:  [0,1,5,10]
      output: [0,3,6,10]

    ,

      input:  [0,2,5,7]
      output: [0,3,6,9]

    ,

      input:  [0,2,7,9]
      output: [0,3,7,10]

    ,

      input:  [0,4,8,12]
      output: [0,4,8,12]

    ]

    completed = 0
    complete = ->
      completed += 1
      if completed is tests.length then done()


    testThrottle = (input, output) ->

      start = Date.now()
      i = 0

      _fn = (args) ->
        diff = Date.now() - start
        assertNear diff, output[i]
        if i is output.length - 1 then complete()
        i++

      fn = throttle _fn, duration

      for time in input
        Q.delay(time).then(fn)

    for test in tests
      input  = test.input.map(multiply)
      output = test.output.map(multiply)
      testThrottle input, output
