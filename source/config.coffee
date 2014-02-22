log = require('log_')('Config', 'blue')

config =

# -----------------------------------------------------------------------------
# SELECT CONFIGURATION
# -----------------------------------------------------------------------------

  use: (platform) ->
    log platform
    for key, value of config[platform]
      config[key] = value


# -----------------------------------------------------------------------------
# DEFAULT CONFIGURATION
# -----------------------------------------------------------------------------

  url: 'http://localhost:8080'
  port: 8080

  client: 'http://beta.nitrotasks.com'

  database_engine: null
  database_config: {}

  redis_config:
    port: 6379
    host: '127.0.0.1'


# -----------------------------------------------------------------------------
# POSSIBLE CONFIGURATIONS
# -----------------------------------------------------------------------------

  heroku:

    url: 'http://nitro-server.herokuapp.com'
    port: process.env.PORT

    # TEMPORARY
    client: '*'

    database_engine: 'pg'
    database_config: process.env.DATABASE_URL

    redis_config: process.env.REDISTOGO_URL


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

    client: '*'

    database_engine: 'mysql'
    database_config:
      host: '127.0.0.1'
      port: 3306
      user: 'nodejs'
      password: 'nodejs'
      database: 'Nitro'


  testing:

    client: '*'

    database_engine: 'mysql'
    database_config:
      host: '127.0.0.1'
      port: 3306
      user: 'nodejs'
      password: 'nodejs'
      database: 'Nitro_Test'
      charset: 'utf8'
      debug: false

  testing_pg:

    database_engine: 'pg'
    database_config: 'postgres://stayrad:@localhost/nitro_server'

  travis:

    database_engine: 'pg'
    database_config: 'postgres://postgres:@127.0.0.1/nitro_travis'


module.exports = config
