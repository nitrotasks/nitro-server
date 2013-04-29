OAuth = require("oauth").OAuth
Keys = require("./keychain")
Q = require "q"

# ------------------------------------------------------------------------------
# PRIVATE FUNCTIONS
# ------------------------------------------------------------------------------

tokens = {}

services =
  ubuntu:
    authUrl: "https://one.ubuntu.com/oauth/authorize/?description=Nitro&oauth_token="
    infoUrl: "https://one.ubuntu.com/api/account/"
    oauth: new OAuth(
      "https://one.ubuntu.com/oauth/request/",
      "https://one.ubuntu.com/oauth/access/",
      "ubuntuone", "hammertime",
      "1.0", "http://sync.nitrotasks.com/api/oauth/callback?service=ubuntu", "PLAINTEXT"
    )
  dropbox:
    authUrl: "https://www.dropbox.com/1/oauth/authorize?oauth_token="
    infoUrl: "https://api.dropbox.com/1/account/info"
    oauth: new OAuth(
      "https://api.dropbox.com/1/oauth/request_token",
      "https://api.dropbox.com/1/oauth/access_token",
      Keys("db_key"), Keys("db_secret"),
      "1.0", "http://sync.nitrotasks.com/api/oauth/callback?service=dropbox", "PLAINTEXT"
    )
  google:
    authUrl: "https://www.google.com/accounts/OAuthAuthorizeToken?oauth_token="
    infoUrl: "https://www.googleapis.com/oauth2/v1/userinfo?alt=json"
    params:
      scope: [
        "https://www.googleapis.com/auth/userinfo.profile"
        "https://www.googleapis.com/auth/userinfo.email"
      ]
      xoauth_displayname: "Nitro"
    oauth: new OAuth(
      "https://www.google.com/accounts/OAuthGetRequestToken",
      "https://www.google.com/accounts/OAuthGetAccessToken",
      "anonymous", "anonymous",
      "1.0A", "http://sync.nitrotasks.com/api/oauth/callback", "HMAC-SHA1"
    )

getAuthUrl = (service, token) ->
  url = services[service].authUrl
  callback = services[service].oauth._authorize_callback
  return url + token + "&oauth_callback=" + callback

# ------------------------------------------------------------------------------
# PUBLIC FUNCTIONS
# ------------------------------------------------------------------------------

API =

  # Returns the request tokens
  request: (service) ->
    deferred = Q.defer()
    oauth = services[service].oauth
    params = services[service].params or {}
    oauth.getOAuthRequestToken params, (err, token, secret) ->
      if err? then return deferred.reject(err)
      request =
        oauth_token: token
        oauth_token_secret: secret
        authorize_url: getAuthUrl(service, token)
      deferred.resolve(request)
    return deferred.promise

  # Store token and verifier
  verify: (service, token, verifier) ->
    tokens[service] ?= {}
    tokens[service][token] = verifier

  # Returns the access tokens
  access: (service, request) ->
    deferred = Q.defer()
    oauth = services[service].oauth
    token = request.oauth_token
    secret = request.oauth_token_secret
    verifier = request.oauth_verifier or tokens[service]?[token]
    oauth.getOAuthAccessToken token, secret, verifier, (err, token, secret) ->
      if err? then return deferred.reject(err)
      access =
        oauth_token: token
        oauth_token_secret: secret
      deferred.resolve(access)
    return deferred.promise

  # Returns the users email and name
  userinfo: (service, access) ->
    deferred = Q.defer()
    oauth = services[service].oauth
    url = services[service].infoUrl
    token = access.oauth_token
    secret = access.oauth_token_secret
    oauth.get url, token, secret, (err, data) ->
      if err? then return deferred.reject(err)
      if typeof(data) is "string" then data = JSON.parse(data)
      email = data.email or data.data.email
      name = data.display_name or data.nickname
      deferred.resolve([email, name])
    return deferred.promise

module.exports = API
