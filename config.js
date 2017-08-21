const path = require('path')
const config = {
  port: process.env.PORT || 8040,
  dist: path.resolve(__dirname, '../nitro/dist'),

  db: {
    connection: process.env.DATABASE_URL || 'postgres://nitro:secret@localhost:5432/nitro',
    testconnection: process.env.DATABASE_URL_TEST || 'postgres://nitro:secret@localhost:5432/nitrotest',
    travisconnection: 'postgres://postgres:@127.0.0.1/nitro_travis'
  },

  jwtsecret: process.env.JWT_Secret || 'secret'
}
module.exports = config