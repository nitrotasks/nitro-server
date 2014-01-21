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

  log = console.log.bind(console)

  # Create 'user' table
  query("""
    CREATE TABLE IF NOT EXISTS `user` (
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
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1;
  """).fail(log)

  query("""
    CREATE TABLE IF NOT EXISTS `user_register` (
     `id`         int(11)      NOT NULL  AUTO_INCREMENT,
     `token`      char(22)     NOT NULL,
     `name`       varchar(100) NOT NULL,
     `email`      varchar(100) NOT NULL,
     `password`   char(60)     NOT NULL,
     `created_at` timestamp    NOT NULL  DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`, `token`)
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1;
  """).fail(log)

  query("""
    CREATE TABLE IF NOT EXISTS `user_login` (
     `user_id`    int(11)   NOT NULL,
     `token`      char(64)  NOT NULL,
     `created_at` timestamp NOT NULL  DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`user_id`, `token`),
      FOREIGN KEY (`user_id`) REFERENCES user(`id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
  """).fail(log)

  query("""
    CREATE TABLE IF NOT EXISTS `user_reset` (
     `user_id`    int(11)      NOT NULL,
     `token`      char(22)     NOT NULL,
     `created_at` timestamp    NOT NULL  DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`user_id`, `token`),
      FOREIGN KEY (`user_id`) REFERENCES user(`id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1;
  """).fail(log)

close = ->
  db.end()

# ---

# Add or update user details
write_user = (user, attrs) ->

  data = {}

  if attrs

    for attr in attrs
      if attr in ['data_task', 'data_list', 'data_pref', 'data_time']
        data[attr] = shrink.pack(user[attr])
      else
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
  sql = 'INSERT INTO user SET ? ON DUPLICATE KEY UPDATE ?'
  query(sql, [data, data]).then (result) ->
    id = result.insertId
    log "Wrote user #{ id }"
    return id


# Get user data
read_user = (uid) ->

  log "Fetching user #{uid}"

  query('SELECT * FROM user WHERE id=?', uid).then (result) ->

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
  query 'SELECT id, name, email FROM user'

# Delete user data
del_user = (uid) ->
  query('DELETE FROM user WHERE id = ?', uid).then ->
    log 'Deleted user', uid

deleteAll = (table) ->
  query "DELETE FROM #{ table }"


# -----------------------------------------------------------------------------
# Login Tokens
# -----------------------------------------------------------------------------

login_add = (user, token) ->
  sql = 'INSERT INTO user_login (user_id, token) VALUES (?, ?)'
  query(sql, [user, token])

login_exists = (user, token) ->
  sql = 'SELECT user_id FROM user_login WHERE user_id=? AND token=?'
  query(sql, [user, token]).then (row) ->
    return !! row.length

login_expire = ->
  date = Date.now() - 1209600 # 60 * 60 * 24 * 14
  sql = 'DELETE FROM user_login WHERE created_at < ?'
  query(sql, date)

login_remove = (user, token) ->
  sql = 'DELETE FROM user_login WHERE user_id=? AND token=?'
  query(sql, [user, token])

login_remove_all = (user) ->
  sql = 'DELETE FROM user_login WHERE user_id=?'
  query(sql, user)

# -----------------------------------------------------------------------------
# Tokens
# -----------------------------------------------------------------------------

parseToken = (token) ->
  match = token.match(/^(\d+)_(\w+)$/)
  if not match then return null
  return [match[1], match[2]]

# -----------------------------------------------------------------------------
# Registration Tokens
# -----------------------------------------------------------------------------

###
 * Add Registration
 *
 * - info (object)
 *   - token (string) : registration token
 *   - name (string) : user name
 *   - email (string) : user email
 *   - password (string) : hash of user password
 * > id + _ + token
###

register_add = (info) ->
  sql = 'INSERT INTO user_register SET ?'
  query(sql, info).then (data) ->
    return data.insertId + '_' + info.token


###
 * Get Registration
 *
 * - token (string) : token returned by register_add
 * > object
 *   - id
 *   - name
 *   - email
 *   - password
###

register_get = (token) ->
  match = parseToken(token)
  return Q.resolve() unless match
  [id, token] = match

  sql = 'SELECT id, name, email, password FROM user_register WHERE id=? AND token=?'
  query(sql, [id, token]).then (rows) ->
    return unless rows.length
    return rows[0]


###
 * Remove Registration
 *
 * - id (int) : registration id
###

register_remove = (id) ->
  sql = 'DELETE FROM user_register WHERE id=?'
  query(sql, id)


# -----------------------------------------------------------------------------
# Reset Tokens
# -----------------------------------------------------------------------------

reset_add = (id, token) ->
  sql = 'INSERT INTO user_reset (user_id, token) VALUES (?, ?)'
  query(sql, [id, token]).then ->
    return id + '_' + token

reset_get = (token) ->
  token = parseToken(token)
  return Q.reject() unless token

  sql = 'SELECT user_id FROM user_reset WHERE user_id=? AND token=?'
  query(sql, token).then (rows) ->
    throw new Error() unless rows.length
    return rows[0].user_id


reset_remove = (token) ->
  token = parseToken(token)
  return Q.reject() unless token

  sql = 'DELETE FROM user_reset WHERE user_id=? AND token=?'
  query(sql, token)


user_find = (email) ->
  sql = 'SELECT id FROM user WHERE email=?'
  query(sql, email).then (rows) ->
    throw new Error() unless rows.length
    return rows[0].id

user_check = (email) ->
  sql = 'SELECT id FROM user WHERE email=?'
  query(sql, email).then (rows) ->
    return !! rows.length


# Remove user
# Update user details
# Set task, list and timestamp data

module.exports =
  connected: connected
  close: close
  query: query
  deleteAll: deleteAll
  user:
    all: all_users
    write: write_user
    read: read_user
    delete: del_user
    find: user_find
    check: user_check
  login:
    add: login_add
    exists: login_exists
    expire: login_expire
    remove: login_remove
    removeAll: login_remove_all
  register:
    add: register_add
    get: register_get
    remove: register_remove
  reset:
    add: reset_add
    get: reset_get
    remove: reset_remove

