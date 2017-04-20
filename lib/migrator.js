const db = require('./db')
const User = require('./models/user')

const migrator = {
  migrate: function() {
    console.log('Migrating Database...')
    User.sync()
  }
}
module.exports = migrator