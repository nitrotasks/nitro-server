###
 * A custom throttle script that handles passing arguments and promises
###

Q = require 'kew'

throttle = (callback, duration) ->

  attributes = []
  running = no
  trailing = no
  lastRun = 0

  fn = ->
    callback attributes
    attributes = []
    lastRun = Date.now()
    if not trailing then running = no

  trail_fn = ->
    trailing = no
    callback attributes
    attributes = []
    lastRun = Date.now()

  return (args...) ->
    deferred = Q.defer()

    for arg in args
      if arg not in attributes then attributes.push arg

    if not running
      deferred.resolve()
      fn()
      running = yes
    else if not trailing
      timeout = Math.max 0, duration - (Date.now() - lastRun)
      Q.delay(timeout).then ->
        deferred.resolve()
        trail_fn()
      trailing = yes
    return deferred.promise

module.exports = throttle
