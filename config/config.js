const path = require('path')
const config = {
  port: process.env.PORT || 8040,
  dist: false,
  // dist: path.resolve(__dirname, '../node_modules/nitrotasks/dist'),
  // dist: path.resolve(__dirname, '../../nitro/dist'),

  development: {
    url: process.env.DATABASE_URL || 'postgres://nitro:secret@localhost:5432/nitro',
    dialect: 'postgres'
  },
  production: {
    url: process.env.DATABASE_URL || 'postgres://nitro:secret@localhost:5432/nitro',
    dialect: 'postgres'
  },
  test: {
    url: process.env.DATABASE_URL_TEST || 'postgres://nitro:secret@localhost:5432/nitrotest',
    dialect: 'postgres'
  },
  travis: {
    url: 'postgres://postgres:@127.0.0.1/nitro_travis',
    dialect: 'postgres'
  },

  jwtsecret: process.env.JWT_Secret || 'secret'
}
module.exports = config