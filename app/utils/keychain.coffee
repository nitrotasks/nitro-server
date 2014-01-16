# Put your passwords in here
# So that you don't accidentally share them on git
Log = require '../utils/log'
fs = require 'fs'
keys = {}

warn = Log 'Keychain', 'red'

try
  data = fs.readFileSync __dirname + '/../../keychain'
catch e
  warn 'Could not load keychain'
  data = '{}'

keys = JSON.parse data.toString()

module.exports = (key) ->
  if not keys.hasOwnProperty(key)
    warn "Key not found for '#{key}'"
  return keys[key]
