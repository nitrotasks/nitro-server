const Sequelize = require('sequelize')
const db = require('../db')

const User = db.define('user', {
  friendlyName: Sequelize.STRING
})

module.exports = User