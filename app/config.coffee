keychain = require './utils/keychain'

config =

  use: (platform) ->
    for key, value of config[platform]
      config[key] = value

  production:

    url: 'http://sync.nitrotasks.com:443'
    port: 8080

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

    url: 'http://localhost:8080'
    port: 8080

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

module.exports = config
