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


  # --------
  # Todo.txt
  # --------

  # "get_todo.txt": (req, res) ->
  #   uid = req.param("uid")
  #   listId = req.param("list")
  #   TodoTxt(uid, listId)
  #     .then ([data]) ->
  #       res.send(data.replace(/\n/g, "<br>"))
  #     .fail (message) ->
  #       res.send(message)

  # "get_todo.html": (req, res) ->
  #   uid = req.param("uid")
  #   listId = req.param("list")
  #   TodoHtml(uid, listId).then ([data]) ->
  #     res.send(data)


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
      .then (user) ->
        res.send("""
<!DOCTYPE html>
<html><head>
<meta charset="utf-8">
<title>Password Reset Sent</title>
<link href='http://fonts.googleapis.com/css?family=Lato:300' rel='stylesheet' type='text/css'>
</head><body><h1 style="
max-width: 500px;
font-family: 'Lato';
font-weight: 300;
text-align: center;
margin: 2em auto;
">Success!<br>You can go back to Nitro to log in.</h1>
</body></html>
          """
      .fail (err) ->
        res.send(err)


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

  "auth":

    # Password Resetting
    "get_forgot": (req, res) ->
      res.send """
<!DOCTYPE html>
<html><head><meta charset="utf-8">
<title>Reset Nitro Password</title><link href='http://fonts.googleapis.com/css?family=Lato:300,400' rel='stylesheet'>
</head><body style="
text-align:center;
font-family:'Lato', sans-serif"><h1 style="
font-weight:300;
font-size:36px;
margin-top:2em">Totally legit password reset page.</h1>
<form method="post" action="#">
<input name="email" type="email" placeholder="Your email" style="
font-size:18px;
border:1px solid #ccc;
padding:5px 7px;
outline:0;
height:24px;
font-family:'Lato', sans-serif;
line-height:22px">
<button style="
font-size:16px;
height: 36px;
padding:5px 7px;
border:1px solid #ccc;
background:#fff;
line-height:22px;
vertical-align:top;
color:#444;
cursor:pointer;
font-family:'Lato', sans-serif">Reset Password</button>
</form><br>
<a href="http://nitrotasks.com/app" style="color:#477fd2">Back to Nitro</a>
</body></html>
      """

    "post_forgot": (req, res) ->
      email = req.body.email.toLowerCase()
      Auth.generateResetToken(email)
        .then (token) ->
          message = """
<!DOCTYPE html>
<html><head>
<meta charset="utf-8">
<title>Password Reset Sent</title>
<link href='http://fonts.googleapis.com/css?family=Lato:300' rel='stylesheet' type='text/css'>
</head><body><h1 style="
max-width: 500px;
font-family: 'Lato';
font-weight: 300;
text-align: center;
margin: 2em auto;
">Hurrah! We have sent you an email to reset your password.</h1>
</body></html>
          """
          link = "<a href=\"http://sync.nitrotasks.com/auth/forgot/#{token}\">Reset Password</a>"
          if DebugMode then return res.send message + "<br><br>" + link

          Mail.send
            to: email
            subject: "Nitro Password Reset"
            html: "Please click the link below to reset your password.<br>" + link
          res.send message

        .fail (err) ->
          res.status(400).send "An error occured. Please try again later."

    "get_forgot/*": (req, res) ->
      token = req.params[0]
      User.checkResetToken(token)
        .then ->
          res.send """
            <h1>Now you can reset your password!</h1>
            <form method="post" action="#">
              <input name="password" type="password" placeholder="Password">
              <input name="passwordConfirmation" type="password" placeholder="Confirmation">
              <button>Reset Password</button>
            </form>
          """
        .fail (err) ->
          res.send err

    "post_forgot/*": (req, res) ->
      password = req.body.password
      confirmation = req.body.passwordConfirmation
      token = req.params[0]

      if password isnt confirmation
        return res.status(401).send """<!DOCTYPE html>
<html><head>
<meta charset="utf-8">
<title>Password Reset Sent</title>
<link href='http://fonts.googleapis.com/css?family=Lato:300' rel='stylesheet' type='text/css'>
</head><body><h1 style="
max-width: 500px;
font-family: 'Lato';
font-weight: 300;
text-align: center;
margin: 2em auto;
">Passwords do not match.<br>Please try again.</h1>
</body></html>"""

      User.checkResetToken(token)
        .then (id) ->

          Q.spread [
            User.get(id)
            Auth.hash(password)
          ], (user, hash) ->
            user.changePassword(hash)
            User.removeResetToken(token)
            res.send """<!DOCTYPE html>
<html><head>
<meta charset="utf-8">
<title>Password Reset Sent</title>
<link href='http://fonts.googleapis.com/css?family=Lato:300' rel='stylesheet' type='text/css'>
</head><body><h1 style="
max-width: 500px;
font-family: 'Lato';
font-weight: 300;
text-align: center;
margin: 2em auto;
">Your password has been changed.</h1>
</body></html>"""
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

# Start Server
server = app.listen(port)

# Start sync
Sync = require "./app/sync"
Sync.init server

module.exports = app
