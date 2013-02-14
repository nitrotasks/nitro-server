http = require('http')
Keys = require('./keychain')

# Generate GET params from object
encode = (params) ->
  string = ""
  for rawKey, rawValue of params
    key = encodeURIComponent(rawKey)
    value = encodeURIComponent(rawValue)
    string += "&#{key}=#{value}"
  string = "?" + string.slice(1)
  return string

Analytics =
  post: (uid) ->

    params =
      p: Keys('analytics')
      fingerprint: uid
      platform: 'browser'
      version: '2.0.0'
      login_type: 'native'
      language: 'EN'
      os: 'osx'

    options =
      host: 'banana.caffeinatedco.de'
      path: "/api/#{encode(params)}"

    http.get(options)

module.exports = Analytics
