# Nitro Sync 2.1 #

[![Build Status](https://travis-ci.org/CaffeinatedCode/nitro-server.png)](https://travis-ci.org/CaffeinatedCode/nitro-server)
[![Coverage Status](https://coveralls.io/repos/CaffeinatedCode/nitro-server/badge.png?branch=master)](https://coveralls.io/r/CaffeinatedCode/nitro-server?branch=master)
[![Dependency Status](https://david-dm.org/CaffeinatedCode/nitro-server.png?theme=shields.io)](https://david-dm.org/CaffeinatedCode/nitro-server)
[![devDependency Status](https://david-dm.org/CaffeinatedCode/nitro-server/dev-status.png?theme=shields.io)](https://david-dm.org/CaffeinatedCode/nitro-server#info=devDependencies)

## Requirements ##
- Node.js and NPM
- Coffeescript
- Microsoft SQL Server or MySQL Server

## To install and run ##
- `npm install` to install the dependencies
- `coffee app/init.coffee` to run the app

## To start in debug mode ##
- Enables logging
- Sends registration tokens directly back to user instead of by email (Check browser console when registering)
- `coffee app/init.coffee --debug`

## To test ##
- `npm test` - to test everything
- `mocha --compilers coffee:coffee-script test/<filename>.coffee` - to test
  only some things.

# About Nitro Sync

## Module Layout

![Modules](module_layout.jpg)

## Storage

All data is stored in a SQL database

Data stored on SQL includes

- All user data
    - ID
    - Name
    - Email
    - Password (bcrypt hash)
    - Task data
    - List data
    - Task and list timestamps (for merging data)
    - Creation timestamp of user account
    - Timestamp of last change to user account
- Login Tokens
- Registration Tokens
- Password Reset Tokens

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

## Copyright & License

Copyright (c) 2014 CaffeinatedCode - Released under the MIT License. 

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
