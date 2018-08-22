# Nitro Sync 3

[![Build Status](https://travis-ci.org/nitrotasks/nitro-server.svg)](https://travis-ci.org/nitrotasks/nitro-server)
[![Maintainability](https://api.codeclimate.com/v1/badges/e736dafb1272ec207bed/maintainability)](https://codeclimate.com/github/nitrotasks/nitro-server/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/e736dafb1272ec207bed/test_coverage)](https://codeclimate.com/github/nitrotasks/nitro-server/test_coverage)
[![Dependency Status](https://david-dm.org/nitrotasks/nitro-server.svg?theme=shields.io)](https://david-dm.org/nitrotasks/nitro-server)
[![devDependency Status](https://david-dm.org/nitrotasks/nitro-server/dev-status.svg?theme=shields.io)](https://david-dm.org/nitrotasks/nitro-server#info=devDependencies)
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fnitrotasks%2Fnitro-server.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2Fnitrotasks%2Fnitro-server?ref=badge_shield)

# Configure

- You'll need PostgreSQL installed - configure the settings in config.js
- Set a strong JWT secret in config.js

## Postgres Docker Sample

This should start Postgres in Docker Nicely, no configuration required in config.js.
`docker run --name nitro-postgres -p 5432:5432 -e POSTGRES_USER=nitro -e POSTGRES_PASSWORD=secret -d postgres`

# Running

- Run `npm run migrate` to run migrations.
- Run with `npm start`. There will be an error if it can't connect to the database.
- Run `npm run migrate:test` to run tests. Recommended to make sure everything is working.
- `npm run test` will fail if run more than once without redoing migrations.
- You'll need to pull the Nitro client in order for the server to host it. <http://github.com/nitrotasks/nitro>


## License
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fnitrotasks%2Fnitro-server.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2Fnitrotasks%2Fnitro-server?ref=badge_large)