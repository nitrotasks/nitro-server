# Nitro Sync 3

[![Build Status](https://travis-ci.org/nitrotasks/nitro-server.svg)](https://travis-ci.org/nitrotasks/nitro-server)
[![Coverage Status](https://coveralls.io/repos/nitrotasks/nitro-server/badge.svg?branch=master)](https://coveralls.io/r/nitrotasks/nitro-server?branch=master)
[![Dependency Status](https://david-dm.org/nitrotasks/nitro-server.svg?theme=shields.io)](https://david-dm.org/nitrotasks/nitro-server)
[![devDependency Status](https://david-dm.org/nitrotasks/nitro-server/dev-status.svg?theme=shields.io)](https://david-dm.org/nitrotasks/nitro-server#info=devDependencies)

# Configure
- You'll need PostgreSQL installed - configure the settings in config.js
- Set a strong JWT secret in config.js

# Running
- Run `npm run sequelize db:migrate` to run migrations.
- Run with `npm start`. There will be an error if it can't connect to the database.
- Test with `npm test`. Recommended to run to make sure everything is working.
- You'll need to pull the Nitro client in order for the server to host it. <http://github.com/nitrotasks/nitro>
