# Nitro Sync (version 2) #

## Requirements ##
- Node.js and NPM
- Coffeescript
- Redis Server
- MySQL Server

## To install and run ##
- `npm install .` to install the dependencies
- `redis-server` to start Redis
- `coffee app.coffee` to run the app

## To start in debug mode ##
- Enables logging
- Sends registration tokens directly back to user instead of by email (Check browser console when registering)
- `coffee app.coffee --debug`

## To test ##
- Install Mocha
- `mocha --compilers coffee:coffee-script test/<filename>.coffee`

# About Nitro Sync

## Storage

We use Redis and MySQL to store the Nitro Sync data.

Data stored on Redis includes

- Authentication tokens
- Password reset tokens
- User ID lookup tables (to quickly get a users ID from their email address)
- Task and list counts

Data stored on MySQL includes

- All user data
    - ID
    - Name
    - Email
    - Password hash
    - Task data
    - List data
    - Task and list timestamps (for merging data)
    - Creation timestamp of user account
    - Timestamp of last change to user account

## Websockets

We use WebSockets (via Socket.IO) to connect to the Nitro client and sync data
in real time.

## Security

Nitro Sync uses node-bcrypt to hash passwords.

All other data is stored unencrypted in the database.

## Privacy

Nitro Sync does not share your data with anyone else.

## Analytics

Nitro Sync does collect analytics, but only very limited data to give us an
idea of how many people use the service.

The only data we track is how many times a user opens the Nitro application.
The login/authentication process stores a record of who logged in and the
current time.

We respect your privacy and there is an option in the Nitro settings panel to
opt out of analytics.

_Nitro Sync Analytics and the opt out feature are both under work and are not
yet implemented._

