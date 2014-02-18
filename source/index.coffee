config = require('./config')
server = require('./server/index')
core   = require('./core/index')
log    = require('log_')('Foreman', 'green')


# -----------------------------------------------------------------------------
# ENVIRONMENT
# -----------------------------------------------------------------------------

environment = process.env.NODE_ENV ?= 'development'
if environment is 'heroku' then require 'newrelic'


# -----------------------------------------------------------------------------
# START NITRO
# -----------------------------------------------------------------------------

startNitro = ->

  # Handle debug mode
  global.DEBUG ?= true # TODO: false
  if DEBUG then log.warn 'Running in debug mode!'

  # Configure application
  config.use(environment)

  # Start app
  core(config).return(config).then(server)


# -----------------------------------------------------------------------------
# EXPORTS
# -----------------------------------------------------------------------------

module.exports = startNitro
