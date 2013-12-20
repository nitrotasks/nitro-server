keychain = require './utils/keychain'

module.exports =

  production:

    redis:
      host: '127.0.0.1'
      port: 6379

    mysql:
      host: keychain 'sql_host'
      port: keychain 'sql_port'
      user: keychain 'sql_user'
      password: keychain 'sql_pass'
      database: keychain 'sql_db'

  development:

    redis:
      host: '127.0.0.1'
      port: 6379

    mysql:
      host: '127.0.0.1'
      port: 3306
      user: 'nodejs'
      password: 'nodejs'
      database: 'Nitro'

  testing:

    redis:
      host: '127.0.0.1'
      port: 9999

    mysql:
      host: '127.0.0.1'
      port: 3306
      user: 'nodejs'
      password: 'nodejs'
      database: 'Nitro_Test'
