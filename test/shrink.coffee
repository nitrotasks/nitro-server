should = require 'should'
shrink = require '../app/utils/shrink'

# Just some random data we want to compress
data =
  Task:
    '1':
      name: 'Task 1'
      date: 1355863711107
      priority: '2'
      notes: 'Just some notes'
    '2':
      name: 'Task 2'
      date: 1355863711407
      priority: '1'
      notes: 'Not many notes'
  List:
    '1':
      name: 'List 1'
    '2':
      name: 'List 2'

# Going to hold the compressed version of data
compressed = ''

# Test if a variable is an object
isObject = (obj) ->
  typeof obj is 'object' and not Array.isArray obj

describe 'shrink ->', ->

  it 'Compress', ->

    # shrink data object without using msgpack
    shrinked = shrink.pack(data, true)

    # Save it as a string so we can test expanding it
    compressed = JSON.stringify shrinked

    # Loops through an objects keys
    # Check that each key is only one char long
    check = (obj) ->
      for k, v of obj
        k.should.have.length 1
        if isObject v
          check v

    check shrinked


  it 'Expand', ->

    # Expand our compressed string
    expanded = shrink.unpack(compressed, true)

    # Compare against the original data object
    expanded.should.eql data
