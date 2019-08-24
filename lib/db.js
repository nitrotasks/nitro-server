const Sequelize = require('sequelize')
const config = require('../config/config.js')
const logger = require('./logger.js')

const isInTest = typeof global.it === 'function'

let connection = config.production
if (isInTest) {
  connection = config.test
}
if (process.env.NODE_ENV === 'travis') {
  connection = config.travis
}

const sequel = new Sequelize(connection.url, {
  ...connection,
  logging: false,
  operatorsAliases: false,
  pool: {
    max: 5,
    min: 0,
    idle: 10000,
    acquire: 60000
  }
})
sequel
  .authenticate()
  .then(() => {
    logger.info('Connected to the database.')
  })
  .catch(err => {
    logger.error({ err: err }, 'Could not connect to the database.')
  })

module.exports = sequel
