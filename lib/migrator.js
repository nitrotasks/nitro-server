const db = require('./db')
const User = require('./models/user')
const Token = require('./models/token')
const List = require('./models/list')
const Task = require('./models/task')

const migrator = {
  migrate: function(force = false) {
  	if (force) {
  		return db.sync({force: force})
  	} else {
  		return db
  	}
  }
}
module.exports = migrator