const Sequelize = require('sequelize')
const db = require('../db')

const User = require('./user')

const Meta = db.define('meta', {
  id: {
    primaryKey: true,
    type: Sequelize.UUID,
    defaultValue: Sequelize.UUIDV4
  },
  key: Sequelize.STRING,
  value: Sequelize.JSONB
})

Meta.belongsTo(User)
module.exports = Meta
