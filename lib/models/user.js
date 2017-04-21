const Sequelize = require('sequelize')
const db = require('../db')

const User = db.define('user', {
  loginType: Sequelize.STRING,
  email: Sequelize.STRING,
  friendlyName: Sequelize.STRING,
  password: Sequelize.STRING,
})

module.exports = User