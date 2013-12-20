# Put your passwords in here
# So that you don't accidentally share them on git
Log = require('./log')('Keychain', 'red')
fs = require 'fs'
keys = {}

try
  data = fs.readFileSync __dirname + '/../keychain'
catch e
  Log 'Could not load keychain'
  data = '{}'

keys = JSON.parse data.toString()

module.exports = (key) ->
  if not keys.hasOwnProperty(key)
   Log "Key not found for '#{key}'"
  return keys[key]
