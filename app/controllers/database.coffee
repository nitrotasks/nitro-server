Q        = require 'kew'
shrink   = require '../utils/shrink'
keychain = require '../utils/keychain'
connect  = require '../controllers/connect'
Log      = require '../utils/log'

log = Log 'Database', 'blue'
warn = Log 'Database', 'red'

db = null
query = null

connected = connect.ready.then ->

  log 'Connecting to MySQL'

  db = connect.mysql
  query = Q.bindPromise db.query, db

  deferred = Q.defer()

  db.connect  (err) ->
    if err
      warn 'Could not connect to MySQL database!'
      return deferred.reject err
    log 'Connected to MySQL server'
    setup()
    deferred.resolve()

  return deferred.promise

# Initialise Nitro database
setup = ->

  # Create 'users' table
  query """
    CREATE TABLE IF NOT EXISTS `users` (
     `id`            int(11)        NOT NULL    AUTO_INCREMENT,
     `name`          varchar(100)   NOT NULL,
     `email`         varchar(100)   NOT NULL,
     `password`      char(60)       NOT NULL,
     `pro`           tinyint(1)     NOT NULL,
     `data_task`     mediumblob     NOT NULL,
     `data_list`     mediumblob     NOT NULL,
     `data_pref`     mediumblob     NOT NULL,
     `data_time`     mediumblob     NOT NULL,
     `index_task`    int(11)        NOT NULL    DEFAULT '0',
     `index_list`    int(11)        NOT NULL    DEFAULT '0',
     `created_at`    timestamp      NOT NULL    DEFAULT '0000-00-00 00:00:00',
     `updated_at`    timestamp      NOT NULL    DEFAULT CURRENT_TIMESTAMP       ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;
  """

close = ->
  db.end()

# ---

# Add or update user details
write_user = (user, attrs) ->

  data = {}

  if attrs

    for attr in attrs
      data[attr] = user[attr]

    # id is required
    data.id = user.id

  else

    # Only update the properties set in `user`

    for property in ['id', 'name', 'email', 'password', 'pro', 'created_at', 'updated_at']
      if user.hasOwnProperty(property)
        data[property] = user[property]

    for property in ['task', 'list', 'pref', 'time']
      property = 'data_' + property
      if user.hasOwnProperty(property)
        data[property] = shrink.pack(user[property])

    for property in ['task', 'list']
      property = 'index_' + property
      if user.hasOwnProperty(property)
        data[property] = user[property]

  # Write to database
  sql = 'INSERT INTO users SET ? ON DUPLICATE KEY UPDATE ?'
  query(sql, [data, data]).then (result) ->
    id = result.insertId
    log "Wrote user #{ id }"
    return id


# Get user data
read_user = (uid) ->

  log "Fetching user #{uid}"

  query('SELECT * FROM users WHERE id=?', uid).then (result) ->

    if result.length is 0
      throw Error

    user = result[0]

    user.data_task = shrink.unpack user.data_task
    user.data_list = shrink.unpack user.data_list
    user.data_pref = shrink.unpack user.data_pref
    user.data_time = shrink.unpack user.data_time

    return user

# Get all users
all_users = ->
  query 'SELECT id, name, email FROM users'

# Delete user data
del_user = (uid) ->
  query('DELETE FROM users WHERE id = ?', uid).then ->
    log 'Deleted user', uid


truncate = (table) ->
  query "TRUNCATE #{ table }"

# Remove user
# Update user details
# Set task, list and timestamp data

module.exports =
  connected: connected
  close: close
  query: query
  truncate: truncate
  user:
    all: all_users
    write: write_user
    read: read_user
    delete: del_user
