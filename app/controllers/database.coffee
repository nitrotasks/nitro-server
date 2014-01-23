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

  query """
    CREATE TABLE IF NOT EXISTS `user` (
      `id`           int(11)        unsigned   NOT NULL    AUTO_INCREMENT,
      `name`         varchar(100)              NOT NULL,
      `email`        varchar(100)              NOT NULL,
      `password`     char(60)                  NOT NULL,
      `pro`          tinyint(1)     unsigned   NOT NULL,
      `created_at`   timestamp                 NOT NULL     DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
  """

  query """
    CREATE TABLE IF NOT EXISTS `task` (
      `id`          int(11)         unsigned   NOT NULL    AUTO_INCREMENT,
      `user_id`     int(11)         unsigned   NOT NULL,
      `list_id`     int(11)         unsigned   NOT NULL,
      `name`        varchar(150)               NOT NULL    DEFAULT '',
      `notes`       varchar(400)               NOT NULL    DEFAULT '',
      `priority`    tinyint(4)      unsigned   NOT NULL,
      `completed`   bigint(20)      unsigned   NOT NULL,
      `date`        bigint(20)      unsigned   NOT NULL,
      PRIMARY KEY (`id`,`user_id`),
      CONSTRAINT `task_user_id` FOREIGN KEY (`user_id`)
      REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
  """

  query """
    CREATE TABLE IF NOT EXISTS `list` (
      `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
      `user_id` int(11) unsigned NOT NULL,
      `name` varchar(150) NOT NULL DEFAULT '',
      PRIMARY KEY (`id`),
      CONSTRAINT `list_user_id` FOREIGN KEY (`user_id`)
      REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
  """

  query """
    CREATE TABLE IF NOT EXISTS `list_tasks` (
      `list_id` int(11) unsigned NOT NULL,
      `task_id` int(11) unsigned NOT NULL,
      PRIMARY KEY (`list_id`,`task_id`),
      CONSTRAINT `list_tasks_task_id` FOREIGN KEY (`task_id`)
      REFERENCES `task` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
      CONSTRAINT `list_tasks_list_id` FOREIGN KEY (`list_id`)
      REFERENCES `list` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
  """

  query """
    CREATE TABLE IF NOT EXISTS `register` (
      `id`           int(11)        unsigned   NOT NULL    AUTO_INCREMENT,
      `token`        char(22)                  NOT NULL,
      `name`         varchar(100)              NOT NULL,
      `email`        varchar(100)              NOT NULL,
      `password`     char(60)                  NOT NULL,
      `created_at`   timestamp                 NOT NULL    DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`,`token`)
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
  """

  query """
    CREATE TABLE IF NOT EXISTS `login` (
      `user_id`      int(11)        unsigned   NOT NULL,
      `token`        char(64)                  NOT NULL,
      `created_at`   timestamp                 NOT NULL    DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`user_id`,`token`),
      CONSTRAINT `login_user_id` FOREIGN KEY (`user_id`)
      REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
  """

  query """
    CREATE TABLE IF NOT EXISTS `reset` (
      `user_id`      int(11)        unsigned   NOT NULL,
      `token`        char(22)                  NOT NULL,
      `created_at`   timestamp                 NOT NULL    DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`user_id`,`token`),
      CONSTRAINT `reset_user_id` FOREIGN KEY (`user_id`)
      REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
  """

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
  query 'DELETE FROM ' + table


# -----------------------------------------------------------------------------
# Login Tokens
# -----------------------------------------------------------------------------

login_add = (user, token) ->
  sql = 'INSERT INTO login (user_id, token) VALUES (?, ?)'
  query(sql, [user, token])

login_exists = (user, token) ->
  sql = 'SELECT user_id FROM login WHERE user_id=? AND token=?'
  query(sql, [user, token]).then (row) ->
    return !! row.length

login_expire = ->
  date = Date.now() - 1209600 # 60 * 60 * 24 * 14
  sql = 'DELETE FROM login WHERE created_at < ?'
  query(sql, date)

login_remove = (user, token) ->
  sql = 'DELETE FROM login WHERE user_id=? AND token=?'
  query(sql, [user, token])

login_remove_all = (user) ->
  sql = 'DELETE FROM login WHERE user_id=?'
  query(sql, user)

# -----------------------------------------------------------------------------
# Tokens
# -----------------------------------------------------------------------------

parseToken = (token) ->
  match = token.match(/^(\d+)_(\w+)$/)
  if match is null then return null
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
  sql = 'INSERT INTO register SET ?'
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

  sql = 'SELECT id, name, email, password FROM register WHERE id=? AND token=?'
  query(sql, [id, token]).then (rows) ->
    return unless rows.length
    return rows[0]


###
 * Remove Registration
 *
 * - id (int) : registration id
###

register_remove = (id) ->
  sql = 'DELETE FROM register WHERE id=?'
  query(sql, id)


# -----------------------------------------------------------------------------
# Reset Tokens
# -----------------------------------------------------------------------------

reset_add = (id, token) ->
  sql = 'INSERT INTO reset (user_id, token) VALUES (?, ?)'
  query(sql, [id, token]).then ->
    return id + '_' + token

reset_get = (token) ->
  token = parseToken(token)
  return Q.reject(new Error) unless token

  sql = 'SELECT user_id FROM reset WHERE user_id=? AND token=?'
  query(sql, token).then (rows) ->
    throw new Error() unless rows.length
    return rows[0].user_id


reset_remove = (token) ->
  token = parseToken(token)
  return Q.reject(new Error) unless token

  sql = 'DELETE FROM reset WHERE user_id=? AND token=?'
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

