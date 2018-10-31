const Sequelize = require('sequelize')
const config = require('../config/config.js')

const isInTest = typeof global.it === 'function'

let connection = config.production.url
if (isInTest) {
  connection = config.test.url
}
if (process.env.NODE_ENV === 'travis') {
	connection = config.travis.url
}

const sequel = new Sequelize(connection, {
  logging: false,
  operatorsAliases: false
})
sequel.authenticate().then(() => {
	console.log('Connected to the database.')
}).catch(err => {
	console.error('Could not connect to the database.')
})

module.exports = sequel