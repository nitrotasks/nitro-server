
# Dependencies
mysql = require 'mysql'
shrink = require './shrink'
Q = require 'q'

# Constants
DATABASE = 'Nitro'

db = mysql.createConnection
  host: '127.0.0.1'
  user: 'root'
  password: 'ggthejoker'

connect = ->

  db.connect (err) ->
    if err
      console.log 'Error connecting to database!'
      throw err
    else
      console.log '> Connected to MySQL server'
      setup()

# Initialise Nitro database
setup = ->

  # Create database
  db.query "CREATE DATABASE IF NOT EXISTS #{DATABASE};"

  # Select Nitro database
  db.query "USE #{DATABASE};"

  # Create 'users' table
  db.query """
    CREATE TABLE IF NOT EXISTS `users` (
     `id`            int(11)        NOT NULL    AUTO_INCREMENT,
     `name`          varchar(100)   NOT NULL,
     `email`         varchar(100)   NOT NULL,
     `password`      char(60)       NOT NULL,
     `pro`           tinyint(1)     NOT NULL,
     `tasks`         mediumblob     NOT NULL,
     `lists`         mediumblob     NOT NULL,
     `timestamps`    mediumblob     NOT NULL,
     `tasks_index`   int(11)        NOT NULL,
     `lists_index`   int(11)        NOT NULL,
     `created_at`    timestamp      NOT NULL    DEFAULT           '0000-00-00 00:00:00',
     `updated_at`    timestamp      NOT NULL    DEFAULT           CURRENT_TIMESTAMP       ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;
  """

  console.log '> Set up Nitro database'

# Close database connection
close = ->
  db.end()

# ---

# Add or update user details
write_user = (user) ->

  console.log 'Writing data to database'
  console.log user

  deferred = Q.defer()

  # Convert JSON objects into strings
  tasks = if user.tasks? then JSON.stringify(user.tasks) else ""
  lists = if user.lists? then JSON.stringify(user.lists) else ""
  timestamps = if user.timestamps? then JSON.stringify(user.timestamps) else ""

  data =
    id:           user.id
    name:         user.name
    email:        user.email
    password:     user.password
    pro:          user.pro
    tasks:        shrink.compress(user.data_Task or {})
    lists:        shrink.compress(user.data_List or {})
    timestamps:   shrink.compress(user.data_Time or {})
    tasks_index:  user.index_Task or 0
    lists_index:  user.index_List or 0
    created_at:   user.created_at or new Date()
    # updated_at: set automatically by database


  console.log data
    
  # Write to database
  db.query "INSERT INTO users SET ? ON DUPLICATE KEY UPDATE ?", [data, data], (err, result) ->
    if err then return deferred.reject(err)
    # Return the user id
    deferred.resolve(result.insertId)

  return deferred.promise


# Get user data
read_user = (uid, fn) ->
  deferred = Q.defer()

  db.query "SELECT * FROM users WHERE id=?", uid, (err, result) ->
    if err then return deferred.reject(err)

    if result.length > 0
      _user = result[0]
      user =
        id:          _user.id
        name:        _user.name
        email:       _user.email
        password:    _user.password
        pro:         _user.pro
        data_Task:   shrink.expand _user.tasks.toString()
        data_List:   shrink.expand _user.lists.toString()
        data_Time:   shrink.expand _user.timestamps.toString()
        index_Time:  _user.tasks_index
        index_List:  _user.lists_index
        created_at:  _user.created_at
        updated_at:  _user.updated_at

    deferred.resolve(user)
  return deferred.promise

# Delete user data
del_user = (uid, fn) ->
  deferred = Q.defer()
  db.query "DELETE FROM users WHERE id = ?", uid, (err, results) ->
    if err then return deferred.reject(err)
    deferred.resolve(results)
  return deferred.promise

# Remove user
# Update user details
# Set task, list and timestamp data

module.exports = 
  connect: connect
  close: close
  user:
    write: write_user
    read: read_user
    delete: del_user
