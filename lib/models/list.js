const Sequelize = require('sequelize')
const db = require('../db')

const User = require('./user')
const Task = require('./task')

const List = db.define(
  'list',
  {
    id: {
      primaryKey: true,
      type: Sequelize.UUID,
      defaultValue: Sequelize.UUIDV4
    },
    name: Sequelize.STRING,
    notes: Sequelize.TEXT,
    sort: Sequelize.STRING,

    // only works in postgres? do we want to support other databases?
    order: {
      type: Sequelize.ARRAY(Sequelize.UUID),
      defaultValue: []
    }
  },
  {
    hooks: {
      beforeBulkDestroy: function(options) {
        options.individualHooks = true
        return options
      },
      beforeDestroy: async function(list) {
        // for whatever reason, cascade doesn't work
        await list.setUsers(null)
        await Task.destroy({
          where: {
            listId: list.id
          }
        })
      }
    }
  }
)

User.addHook('afterCreate', async function(user, options) {
  const inbox = await List.create({
    name: 'nitrosys-inbox'
  })
  await inbox.addUser(user)
})

// for the future when we can have shared lists
List.belongsToMany(User, { through: 'listaccess' })
List.hasMany(Task)

module.exports = List
