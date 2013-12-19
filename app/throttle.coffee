
throttle = (callback, duration) ->

  args = []
  running = no
  trailing = no
  lastRun = 0

  fn = ->
    callback args
    lastRun = Date.now()
    args = []
    if not trailing then running = no

  trail_fn = ->
    trailing = no
    callback args
    lastRun = Date.now()
    args = []

  return (arg) ->
    if arg not in args then args.push arg
    if not running
      fn()
      running = yes
    else if not trailing
      timeout = duration - (Date.now() - lastRun)
      setTimeout trail_fn, timeout
      trailing = yes

module.exports = throttle
