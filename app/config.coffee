keychain = require './utils/keychain'
Log = require './utils/log'

log = Log('config', 'blue')

config =

  use: (platform) ->
    log platform
    for key, value of config[platform]
      config[key] = value

  production:

    url: 'http://sync.nitrotasks.com'
    port: 8080

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

  heroku:

    url: 'http://nitro-server.herokuapp.com'
    port: process.env.PORT

    database_engine: 'pg'
    database_config: process.env.DATABASE_URL

  azure:

    database_engine: 'mssql'

    database_config:
      user: 'nodejs'
      password: 'nodejs'
      server: 'localhost'
      database: 'Nitro'
      options:
        port: ''
        instanceName: 'SQLEXPRESS'

  development:

    url: 'http://localhost:8080'
    port: 8080

    database_engine: 'mysql'

    database_config:
      host: '127.0.0.1'
      port: 3306
      user: 'nodejs'
      password: 'nodejs'
      database: 'Nitro'

  testing:

    url: 'http://localhost:8080'
    port: 8080

    database_engine: 'mysql'

    database_config:
      host: '127.0.0.1'
      port: 3306
      user: 'nodejs'
      password: 'nodejs'
      database: 'Nitro_Test'
      charset: 'utf8'

  travis:

    url: 'http://localhost:8080'
    port: 8080

    database_engine: 'mysql'

    database_config:
      url: '127.0.0.1'
      port: 3306
      user: 'travis'
      password: ''
      database: 'nitro_travis'
      encoding: 'utf8'


module.exports = config
