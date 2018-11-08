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

  jwtstrategy: process.env.JWT_Strategy || 'bearer',
  jwtaudience: process.env.JWT_Audience || 'https://uat.nitrotasks.com/a/',
  jwtissuer: process.env.JWT_Issuer || 'https://dymajo.au.auth0.com/',
  jwksuri: process.env.JWKS_Uri || 'https://dymajo.au.auth0.com/.well-known/jwks.json',
  jwtsecret: process.env.JWT_Secret || 'secret'
}
module.exports = config