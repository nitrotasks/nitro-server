const Sequelize = require('sequelize')
const db = require('../db')

const Task = db.define('task', {
  name: Sequelize.STRING
})

module.exports = Task