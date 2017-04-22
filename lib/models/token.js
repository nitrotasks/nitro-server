const Sequelize = require('sequelize')
const db = require('../db')

const User = require('./user')

const Token = db.define('token', {
  token: Sequelize.UUID,
  expires: Sequelize.DATE,
  userAgent: Sequelize.STRING,
})

Token.belongsTo(User)
module.exports = Token