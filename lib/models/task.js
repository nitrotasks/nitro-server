const Sequelize = require('sequelize')
const db = require('../db')

const Task = db.define('task', {
  id: {
    primaryKey: true,
    type: Sequelize.UUID,
    defaultValue: Sequelize.UUIDV4,
  },
  name: Sequelize.STRING
})

module.exports = Task