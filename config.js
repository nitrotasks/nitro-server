const config = {
  port: 8040,

  db: {
    connection: process.env.DATABASE_URL || 'postgres://nitro:secret@localhost:5432/nitro',
    testconnection: process.env.DATABASE_URL_TEST || 'postgres://nitro:secret@localhost:5432/nitrotest',
    travisconnection: 'postgres://postgres:@127.0.0.1/nitro_travis'
  },

  jwtsecret: 'secret'
}
module.exports = config