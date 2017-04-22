const Sequelize = require('sequelize')
const db = require('../db')

const User = db.define('user', {
  id: {
    primaryKey: true,
    type: Sequelize.UUID,
    defaultValue: Sequelize.UUIDV4,
  },
  loginType: Sequelize.STRING,
  username: { type: Sequelize.STRING, unique: true, allowNull: false},
  email: Sequelize.STRING,
  friendlyName: Sequelize.STRING,
  password: Sequelize.STRING,
})

module.exports = User