const Sequelize = require('sequelize')
const db = require('../db')

const User = require('./user')
const Task = require('./task')

const List = db.define('list', {
  id: {
    primaryKey: true,
    type: Sequelize.UUID,
    defaultValue: Sequelize.UUIDV4,
  },
  name: Sequelize.STRING,
  // unlimited. Might have to truncate in the controller.
  notes: Sequelize.TEXT,

	// only works in postgres? do we want to support other databases?
  order: {
  	type: Sequelize.ARRAY(Sequelize.UUID),
  	defaultValue: []
  }
})
// for the future when we can have shared lists
List.belongsToMany(User, {through: 'listaccess'})
List.hasMany(Task)

module.exports = List