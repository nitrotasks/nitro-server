const db = require('./db')
const User = require('./models/user')
const List = require('./models/list')
const Task = require('./models/task')

const migrator = {
  migrate: function() {
    console.log('Migrating Database...')
    db.sync()
  }
}
module.exports = migrator