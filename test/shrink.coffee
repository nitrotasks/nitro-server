assert = require "assert"
Shrink = require "../app/shrink"

# Just some random data we want to compress
data =
  Task:
    "1":
      name: "Task 1"
      date: 1355863711107
      priority: "2"
      notes: "Just some notes"
    "2":
      name: "Task 2"
      date: 1355863711407
      priority: "1"
      notes: "Not many notes"
  List:
    "1":
      name: "List 1"
    "2":
      name: "List 2"

# Going to hold the compressed version of data
compressed = ""

# Test if a variable is an object
isObject = (obj) ->
  typeof obj is "object" and not Array.isArray obj

describe "Shrink ->", ->

  it "Compress", ->

    # Shrink data object
    shrinked = Shrink.compress data

    # Save it as a string so we can test expanding it
    compressed = JSON.stringify shrinked

    # Loops through an objects keys
    # Check that each key is only one char long
    check = (obj) ->
      for k, v of obj
        assert.equal k.length, 1
        if isObject v
          check v
    check shrinked


  it "Expand", ->

    # Expand our compressed string
    expanded = Shrink.expand(compressed)

    # Compare against the original data object
    assert.equal JSON.stringify(expanded), JSON.stringify(data)
