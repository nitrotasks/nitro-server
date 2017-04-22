const config = {
  port: 8040,

  db: {
    connection: process.env.DATABASE_URL || 'postgres://nitro:secret@localhost:5432/nitro'
  },

  jwtsecret: 'secret'
}
module.exports = config