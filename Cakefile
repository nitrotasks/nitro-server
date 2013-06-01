{exec} = require 'child_process'

task 'build', 'Build project to bin', ->

  exec 'coffee --compile --output bin/ index.coffee', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr

  exec 'coffee --compile --output bin/app app', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
