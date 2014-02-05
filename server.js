/*
 * Start Nitro Server
 */

global.DEBUG = true;

// Include the CoffeeScript interpreter so that .coffee files will work
var coffee = require('coffee-script');

// Explicitly register the compiler if required. This became necessary in CS 1.7
if (typeof coffee.register !== 'undefined') coffee.register();

// Include our application file
var app = require('./app/init.coffee');