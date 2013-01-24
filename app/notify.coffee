# Deprecated because no-one uses email anyway

User = require "./storage"
mail = require "./mail"

Notify =

  # Prevent duplicate timers
  status: off

  # Start notifications running
  init: ->
    return unless not @status
    console.log "Starting notifications!"
    @status = on
    startLoop()

  check: ->
    time = new Date().getHours() + 1
    console.log time
    console.log "Sending notifications #{count}"
    count++

count = 0

# Start the loop!
startLoop = ->
  setTimeout =>
    Notify.check()
    startLoop()
  , getTime()

# Return the number of milliseconds until the next hour
getTime = ->
  now = Date.now()
  hour = 10000 # 3600000 # 60 * 60 * 1000
  nextHour = hour * Math.ceil( now / hour )
  timeToNextHour = nextHour - now
  return timeToNextHour

sendNotification = ->
  options =
    to: "dev@stayradiated.com"
    subject: "You have upcoming tasks"
    text: "You have upcoming tasks"
  mail.send options

module.exports = Notify

#! For development purporses only
Notify.init()
sendNotification()
