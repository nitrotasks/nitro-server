const Sequelize = require('sequelize')
const config = require('../config')

const isInTest = typeof global.it === 'function'

let connection = config.db.connection
if (isInTest) {
  connection = config.db.testconnection
}

const sequel = new Sequelize(connection, {
  logging: false
})

module.exports = sequel