const Sequelize = require('sequelize')
const db = require('../db')

const User = require('./user')

const List = db.define('list', {
  name: Sequelize.STRING
})
// for the future when we can have shared lists
List.belongsToMany(User, {through: 'listaccess'})

module.exports = List