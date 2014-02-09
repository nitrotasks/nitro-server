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

  heroku:

    url: 'http://nitro-server.herokuapp.com'
    port: process.env.PORT

    database_engine: 'pg'
    database_config: process.env.DATABASE_URL

  azure:

    url: 'http://nitro.azurewebsites.net'
    port: process.env.PORT

    database_engine: 'mssql'

    database_config:
      server: process.env.DATABASE_HOST
      user: process.env.DATABASE_USER
      password: process.env.DATABASE_PASS
      database: process.env.DATABASE_DB
      options:
        encrypt: true

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


  testing_pg:

    url: 'http://localhost:8080'
    port: 8080

    database_engine: 'pg'
    database_config: 'postgres://stayrad:@localhost/nitro_server'

  travis:

    url: 'http://localhost:8080'
    port: 8080

    database_engine: 'pg'
    database_config: 'postgres://postgres:@127.0.0.1/nitro_travis'


module.exports = config
