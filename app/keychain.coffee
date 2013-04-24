# Put your passwords in here
# So that you don't accidentally share them on git
keys =
  "username": "password"

module.exports = (key) ->
  if not keys.hasOwnProperty(key)
    console.warn "(KeyChain) key not found: #{key}"
  keys[key]
