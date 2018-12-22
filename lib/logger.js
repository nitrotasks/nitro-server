const bunyan = require('bunyan')

const logger = bunyan.createLogger({
  name: 'nitro-server',
  serializers: bunyan.stdSerializers
})

module.exports = logger
