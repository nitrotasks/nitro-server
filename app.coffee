express = require "express"
Auth    = require "./app/auth"
User    = require "./app/storage"
Q       = require "q"
Mail    = require "./app/mail"
TodoTxt = require "./app/todo.txt"
TodoHtml = require "./app/todo.html"

port = 8080

app = express()

# Serve up static files in the public folder
app.configure ->
  # app.use express.static('/var/www/html/nitro/public')
  app.use express.bodyParser()

  # Allow CORS
  app.all "/*", (req, res, next) ->
    res.header "Access-Control-Allow-Origin", "*"
    res.header "Access-Control-Allow-Headers", "X-Requested-With"
    next()

global.DebugMode = DebugMode = off
app.__debug = ->
  process.env.NODE_ENV = "development"
  global.DebugMode = DebugMode = on
  console.warn "\u001b[31mRunning in debug mode!\u001b[0m"

# Enable debug mode if passed as argument
if "--debug" in process.argv then app.__debug()

# Redirect requests to beta.nitrotasks.com
app.get "/", (req, res) ->
  res.redirect('http://beta.nitrotasks.com')

# GET and POST requests
api =

  # ------------------
  # PayPal integration
  # ------------------

  "get_pro": (req, res) ->
    uid = req.param("uid")
    # code = req.body.code
    console.log uid

    User.get(uid)
      .then (user) ->
        user.changeProStatus(1)
        res.end()
      .fail ->
        res.status(400).send('err')


  # ------------
  # Registration
  # ------------

  "post_register": (req, res) ->
    user =
      name: req.body.name
      email: req.body.email.toLowerCase()
      password: req.body.password
    Auth.register(user.name, user.email, user.password)
      .then (token) ->
        link = "http://sync.nitrotasks.com/register/#{token}"
        if DebugMode then return res.send [link, token]
        # Send email to user
        Mail.send
          to: user.email
          subject: "Verify your email address"
          html: """
            Hi #{user.name}!
            <br><br>
            Thanks for signing up to Nitro.
            <br><br>
            You'll need to click this link to verify your account first though:
            <a href="#{link}">#{link}</a>
          """
        res.send "true"
      .fail (err) ->
        res.status(400).send err

  "get_register/*": (req, res) ->
    token = req.params[0]
    Auth.verifyRegistration(token)
      .then (user) -> res.sendfile(__dirname + '/pages/auth_success.html')
      .fail (err) -> res.sendfile(__dirname + '/pages/auth_error.html')


  # -----
  # Login
  # -----

  "post_login": (req, res) ->
    user =
      email: req.body.email.toLowerCase()
      password: req.body.password
    Auth.login(user.email, user.password)
      .then (data) ->
        res.send(data)
      .fail (err) ->
        res.status(401).send err


  # -----
  # OAuth
  # -----

  "oauth":

    "get_callback": (req, res) ->
      service = req.param("service")
      token = req.param("oauth_token")
      verifier = req.param("oauth_verifier")
      Auth.oauth.verify(service, token, verifier)
      url = "http://beta.nitrotasks.com"
      res.redirect(301, url)

    "post_request": (req, res) ->
      service = req.body.service
      Auth.oauth.request(service).then (request) ->
        res.send request

    "post_access": (req, res) ->
      service = req.body.service
      request =
        oauth_token: req.body.token
        oauth_token_secret: req.body.secret
      Auth.oauth.access(service, request).then (access) ->
        res.send access

    "post_login": (req, res) ->
      service = req.body.service
      access =
        oauth_token: req.body.token
        oauth_token_secret: req.body.secret
      Auth.oauth.login(service, access)
        .then (data) ->
          res.send data
        .fail (err) ->
          res.status(401).send err

  # ----
  # Auth
  # ----

  # Password Resetting
  "get_forgot": (req, res) ->
    res.sendfile(__dirname + '/pages/reset.html')

  "post_forgot": (req, res) ->
    email = req.body.email.toLowerCase()
    Auth.generateResetToken(email)
      .then (token) ->
        link = "<a href=\"http://sync.nitrotasks.com/forgot/#{token}\">http://sync.nitrotasks.com/forgot/#{token}</a>"
        if DebugMode then return res.send(link)

        Mail.send
          to: email
          subject: "Nitro Password Reset"
          html: """
            <p>To reset your password, click the link below</p>
            <p>#{link}</p>
            <p>If you did not request your password to be reset, you can just ignore this email and your password will remain the same.</p>
            <p>- Nitrotasks</p>
          """
        res.sendfile(__dirname + '/pages/reset_email.html')

      .fail (err) ->
        res.status(400).sendfile(__dirname + '/pages/error.html')

  "get_forgot/*": (req, res) ->
    token = req.params[0]
    User.checkResetToken(token)
      .then ->
        res.sendfile(__dirname + '/pages/reset_form.html')
        .fail (err) ->
          res.sendfile(__dirname + '/pages/error.html')

  "post_forgot/*": (req, res) ->
    password = req.body.password
    confirmation = req.body.passwordConfirmation
    token = req.params[0]

    if password isnt confirmation
      return res.status(401).sendfile(__dirname + '/pages/reset_mismatch.html')

    User.checkResetToken(token)
      .then (id) ->

        Q.spread [
          User.get(id)
          Auth.hash(password)
        ], (user, hash) ->
          user.changePassword(hash)
          User.removeResetToken(token)
          res.sendfile(__dirname + '/pages/reset_success.html')
        , (err) ->
          res.status(401).send err


# Bind requests to Express App
bind = (obj, prefix, app) ->
  for key, value of obj
    if (typeof value is "object") and not Array.isArray value
      bind value, "#{prefix}/#{key}", app
    else
      if key.slice(0,4) is "get_"
        app.get "#{prefix}/#{key.slice(4)}", value
      else if key.slice(0,5) is "post_"
        app.post "#{prefix}/#{key.slice(5)}", value
bind api, "", app

app.get "*", (req, res) ->
  res.send "what???", 404

# Start Server
server = app.listen(port)

# Start sync
Sync = require "./app/sync"
Sync.init server

module.exports = app
