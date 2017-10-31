# Nitro Sync 3

[![Build Status](https://travis-ci.org/nitrotasks/nitro-server.svg)](https://travis-ci.org/nitrotasks/nitro-server)
[![Maintainability](https://api.codeclimate.com/v1/badges/e736dafb1272ec207bed/maintainability)](https://codeclimate.com/github/nitrotasks/nitro-server/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/e736dafb1272ec207bed/test_coverage)](https://codeclimate.com/github/nitrotasks/nitro-server/test_coverage)
[![Dependency Status](https://david-dm.org/nitrotasks/nitro-server.svg?theme=shields.io)](https://david-dm.org/nitrotasks/nitro-server)
[![devDependency Status](https://david-dm.org/nitrotasks/nitro-server/dev-status.svg?theme=shields.io)](https://david-dm.org/nitrotasks/nitro-server#info=devDependencies)

# Configure
- You'll need PostgreSQL installed - configure the settings in config.js
- Set a strong JWT secret in config.js

# Running
- Run `npm run migrate` to run migrations.
- Run with `npm start`. There will be an error if it can't connect to the database.
- Run `npm run migrate:test` to run tests. Recommended to make sure everything is working.
- `npm run test` will fail if run more than once without redoing migrations.
- You'll need to pull the Nitro client in order for the server to host it. <http://github.com/nitrotasks/nitro>
