const Sequelize = require('sequelize')
const db = require('../db')

const User = require('./user')

const Token = db.define('token', {
  id: {
    primaryKey: true,
    type: Sequelize.UUID,
    defaultValue: Sequelize.UUIDV4,
  },
  expires: Sequelize.DATE,
  userAgent: Sequelize.STRING,
})

Token.belongsTo(User)
module.exports = Token