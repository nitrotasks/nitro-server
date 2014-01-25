keychain = require './utils/keychain'

config =

  use: (platform) ->
    for key, value of config[platform]
      config[key] = value

  production:

    url: 'http://sync.nitrotasks.com'
    port: process.env.PORT || 8080

    database:
      engine: keychain 'sql_type'
      host: keychain 'sql_host'
      port: keychain 'sql_port'
      user: keychain 'sql_user'
      password: keychain 'sql_pass'
      database: keychain 'sql_db'

      # engine: process.env.NITRO_ENGINE
      # host: process.env.NITRO_SQL_HOST
      # port: process.env.NITRO_SQL_PORT
      # user: process.env.NITRO_SQL_USER
      # password: process.env.NITRO_SQL_PASS
      # database: process.env.NITRO_SQL_DB

  development:

    url: 'http://localhost:8080'
    port: process.env.PORT || 8080

    database:
      engine: 'mysql'
      host: '127.0.0.1'
      port: 3306
      user: 'nodejs'
      password: 'nodejs'
      database: 'Nitro'

    # database:
    #   engine: 'mssql'
    #   user: 'nodejs'
    #   password: 'nodejs'
    #   server: 'localhost'
    #   database: 'Nitro'
    #   options:
    #     port: ''
    #     instanceName: 'SQLEXPRESS'

  testing:

    url: 'http://localhost:8080'
    port: 8080

    database:
      engine: 'mysql'
      host: '127.0.0.1'
      port: 3306
      user: 'nodejs'
      password: 'nodejs'
      database: 'Nitro_Test'
      charset: 'utf8'

module.exports = config
