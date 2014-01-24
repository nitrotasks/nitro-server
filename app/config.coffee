keychain = require './utils/keychain'

config =

  use: (platform) ->
    for key, value of config[platform]
      config[key] = value

  production:

    url: 'http://sync.nitrotasks.com'
    port: process.env.PORT || 8080

    mysql:
      host: process.env.NITRO_SQL_HOST
      port: process.env.NITRO_SQL_PORT
      user: process.env.NITRO_SQL_USER
      password: process.env.NITRO_SQL_PASS
      database: process.env.NITRO_SQL_DB
      # host: keychain 'sql_host'
      # port: keychain 'sql_port'
      # user: keychain 'sql_user'
      # password: keychain 'sql_pass'
      # database: keychain 'sql_db'

  development:

    url: 'http://localhost:8080'
    port: process.env.PORT || 8080

    mysql:
      host: '127.0.0.1'
      port: 3306
      user: 'nodejs'
      password: 'nodejs'
      database: 'Nitro'


  testing:

    url: 'http://localhost:8080'
    port: 8080

    mysql:
      host: '127.0.0.1'
      port: 3306
      user: 'nodejs'
      password: 'nodejs'
      database: 'Nitro_Test'

module.exports = config
