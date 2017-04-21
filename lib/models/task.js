const Sequelize = require('sequelize')
const db = require('../db')

const List = require('./list')

const Task = db.define('task', {
  name: Sequelize.STRING
})
// for the future when we can have shared lists
Task.belongsTo(List)

module.exports = Task