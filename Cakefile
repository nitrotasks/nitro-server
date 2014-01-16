{exec, spawn} = require 'child_process'

task 'build', 'Build project to bin', ->

  exec 'coffee --compile --output bin/app app', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr

task 'editor', 'Start editor', ->

  app = spawn 'coffee', ['editor/server/index.coffee']

  log = (message) ->
    console.log(message.toString())

  app.stdout.on 'data', log
  app.stderr.on 'data', log

  app.on 'error', log
  app.on 'close', log
