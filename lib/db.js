const Sequelize = require('sequelize')
const config = require('../config')

const sequelize = new Sequelize(config.db.connection)
module.exports = sequelize