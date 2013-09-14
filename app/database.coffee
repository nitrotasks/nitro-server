
# Dependencies
mysql = require 'mysql'
shrink = require './shrink'
keychain = require './keychain'
Q = require 'q'
Log = require('./log')('Database', 'blue')

db = mysql.createConnection
  host:      keychain('sql_host')
  user:      keychain('sql_user')
  password:  keychain('sql_pass')
  port:      keychain('sql_port')
  database:  'Nitro'

# Connect to the MySQL server
connect = ->

  deferred = Q.defer()

  db.connect (err) ->
    if err
      Log 'Error while connecting!'
      deferred.reject(err)
    else
      Log 'Connected to MySQL server'
      setup()
      deferred.resolve()

  return deferred.promise

# Initialise Nitro database
setup = ->

  # Create database
  # db.query "CREATE DATABASE IF NOT EXISTS #{DATABASE};"

  # Select Nitro database
  # db.query "USE #{DATABASE};"

  # Create 'users' table
  db.query '''
    CREATE TABLE IF NOT EXISTS `users` (
     `id`            int(11)        NOT NULL    AUTO_INCREMENT,
     `name`          varchar(100)   NOT NULL,
     `email`         varchar(100)   NOT NULL,
     `password`      char(60)       NOT NULL,
     `pro`           tinyint(1)     NOT NULL,
     `data_Task`     mediumblob     NOT NULL,
     `data_List`     mediumblob     NOT NULL,
     `data_Setting`  mediumblob     NOT NULL,
     `data_Time`     mediumblob     NOT NULL,
     `index_Task`    int(11)        NOT NULL    DEFAULT '0',
     `index_List`    int(11)        NOT NULL    DEFAULT '0',
     `created_at`    timestamp      NOT NULL    DEFAULT '0000-00-00 00:00:00',
     `updated_at`    timestamp      NOT NULL    DEFAULT CURRENT_TIMESTAMP       ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;
  '''

# Close database connection
close = ->
  db.end()

# ---

# Add or update user details
write_user = (user) ->

  console.log 'writing user'

  deferred = Q.defer()

  # Only update the properties set in `user`

  data = {}

  for property in ['id', 'name', 'email', 'password', 'pro', 'created_at', 'updated_at']
    if user.hasOwnProperty(property)
      data[property] = user[property]

  for property in ['Task', 'List', 'Setting', 'Time']
    property = 'data_' + property
    if user.hasOwnProperty(property)
      data[property] = shrink.pack(user[property])

  for property in ['Task', 'List']
    property = 'index_' + property
    if user.hasOwnProperty(property)
      data[property] = user[property]

  # Write to database
  db.query 'INSERT INTO users SET ? ON DUPLICATE KEY UPDATE ?', [data, data], (err, result) ->
    if err then return deferred.reject(err)

    Log "Wrote user #{result.insertId}"

    # Return the user id
    deferred.resolve(result.insertId)

  return deferred.promise


# Get user data
read_user = (uid) ->

  Log "Fetching user #{uid}"

  deferred = Q.defer()

  db.query 'SELECT * FROM users WHERE id=?', uid, (err, result) ->
    if err then return deferred.reject(err)

    if result.length > 0
      _user = result[0]
      user =
        id:             _user.id
        name:           _user.name
        email:          _user.email
        password:       _user.password
        pro:            _user.pro
        data_Task:      shrink.unpack(_user.data_Task)
        data_List:      shrink.unpack(_user.data_List)
        data_Setting:   shrink.unpack(_user.data_Setting)
        data_Time:      shrink.unpack(_user.data_Time)
        index_Task:     _user.index_Task
        index_List:     _user.index_List
        created_at:     _user.created_at
        updated_at:     _user.updated_at

    deferred.resolve(user)
  return deferred.promise

all_users = ->
  deferred = Q.defer()
  db.query 'SELECT id, name, email FROM users', (err, results) ->
    if err then return deferred.reject(err)
    deferred.resolve(results)
  return deferred.promise

# Delete user data
del_user = (uid) ->
  deferred = Q.defer()
  db.query 'DELETE FROM users WHERE id = ?', uid, (err, results) ->
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
    all: all_users
    write: write_user
    read: read_user
    delete: del_user
