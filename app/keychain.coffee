# Put your passwords in here
# So that you don't accidentally share them on git
fs = require 'fs'
keys = {}

try
  data = fs.readFileSync './keychain'
catch e
  console.error("(KeyChain) Could not load keychain")
  data = "{}"

keys = JSON.parse data.toString()

module.exports = (key) ->
  if not keys.hasOwnProperty(key)
    console.warn "(KeyChain) key not found: #{key}"
  keys[key]
