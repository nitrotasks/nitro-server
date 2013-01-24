# Nitro Sync (version 2) #

## Requirements ##
- Node.js and NPM
- Coffeescript
- Redis Server

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
