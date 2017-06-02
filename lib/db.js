const Sequelize = require('sequelize')
const config = require('../config')

const isInTest = typeof global.it === 'function'

let connection = config.db.connection
if (isInTest) {
  connection = config.db.testconnection
}
if (process.env.NODE_ENV === 'travis') {
	connection = config.db.travisconnection
}

const sequel = new Sequelize(connection, {
  logging: false
})

module.exports = sequel