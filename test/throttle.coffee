Q        = require 'kew'
should   = require 'should'
throttle = require '../app/utils/throttle'

log = console.log.bind(console)

describe 'throttle', ->

  it 'should throttle', (done) ->

    duration = 40
    interval = 10
    last = -Infinity
    count = 0

    fn = (args) ->

      now = Date.now()
      diff = now - last
      last = now

      if diff isnt Infinity
        diff.should.be.within duration, duration + 7

      switch count++

        when 0
          args.should.eql [0]

        when 1
          args.should.eql [1,2,3]

        when 2
          args.should.eql [4, 5,6,7]

        when 3
          args.should.eql [8, 9,10,11]

        when 4
          args.should.eql [12, 13,14]
          done()

    fn = throttle fn, duration

    i = 0

    callFn = ->
      fn(i++).fail(log)
      if i < 15
        setTimeout callFn, interval

    callFn()


  it 'should handle multiple arguments', (done) ->

    count = 0

    fn = (args) ->

      switch count++

        when 0
          args.should.eql ['a', 'b', 'c']

        when 1
          args.should.eql ['d', 'e', 'f']
          done()

    fn = throttle fn, 200

    fn 'a', 'b', 'c'
    fn 'd', 'e'
    fn 'e', 'f'


  it 'should return promises', (done) ->

    duration = 100
    start = Date.now()
    count = 0

    fn = (args) ->

      diff = Date.now() - start

      switch count++

        when 0
          diff.should.be.within 0, 7
          args.should.eql ['a']

        when 1
          diff.should.be.within duration, duration + 7
          args.should.eql ['b']

    fn = throttle fn, duration

    promise = Q.all [
      fn 'a'
      fn 'b'
    ]

    promise.then ->
      diff = Date.now() - start
      diff.should.be.within duration, duration + 7
      done()


  it 'should just work properly', (done) ->

    multiply = (i) -> i * 20
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
        diff.should.be.within output[i], output[i] + 7
        if i is output.length - 1 then complete()
        i++

      fn = throttle _fn, duration

      for time in input
        Q.delay(time).then(fn).fail(log)

    for test in tests
      input  = test.input.map(multiply)
      output = test.output.map(multiply)
      testThrottle input, output
