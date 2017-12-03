const Sequelize = require('sequelize')
const db = require('../db')
const User = require('./user')

const ArchivedTask = db.define('archivedtask', {
  id: {
    primaryKey: true,
    type: Sequelize.INTEGER,
    autoIncrement: true
  },
  date: { 
    type: Sequelize.DATE, 
    defaultValue: Sequelize.NOW
  },
  // going to be encoded json, so we can archive things
  // and not have to change the DB when the archive changes
  data: Sequelize.TEXT,
})
ArchivedTask.belongsTo(User)

module.exports = ArchivedTask