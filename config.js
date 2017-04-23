const config = {
  port: 8040,

  db: {
    connection: process.env.DATABASE_URL || 'postgres://nitro:secret@localhost:5432/nitro',
    testconnection: process.env.DATABASE_URL_TEST || 'postgres://nitro:secret@localhost:5432/nitrotest'
  },

  jwtsecret: 'secret'
}
module.exports = config