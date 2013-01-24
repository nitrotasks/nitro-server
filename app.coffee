express = require "express"
Auth    = require "./app/auth"
User    = require "./app/storage"
Q       = require "q"
Mail    = require "./app/mail"

port = process.env.PORT || 5000

app = express()

# Serve up static files in the public folder
app.configure ->
  app.use express.static(__dirname + '/public')
  app.use express.bodyParser()

  # Allow CORS
  app.all "/*", (req, res, next) ->
    res.header "Access-Control-Allow-Origin", "*"
    res.header "Access-Control-Allow-Headers", "X-Requested-With"
    next()

# Enable debug mode if passed as argument
if "--debug" in process.argv
  process.env.NODE_ENV = "development"
  DebugMode = on
  console.warn "\u001b[31mRunning in debug mode!\u001b[0m"

# GET and POST requests
api =
  "v0":


    # ------------
    # Registration
    # ------------

    "post_register": (req, res) ->
      user =
        name: req.body.name
        email: req.body.email
        password: req.body.password
      Auth.register(user.name, user.email, user.password)
        .then (token) ->
          link = "http://localhost:5000/api/v0/register/#{token}"
          if DebugMode then return res.send link
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
          console.error err
          res.status(400).send err

    "get_register/*": (req, res) ->
      token = req.params[0]
      User.getRegistration(token)
        .then (user) ->
          User.add(user.name, user.email, user.pass).then ->
            res.send "success"
        .fail (err) ->
          res.send err


    # -----
    # Login
    # -----

    "post_login": (req, res) ->
      user =
        email: req.body.email
        password: req.body.password
      Auth.login(user.email, user.password)
        .then (data) ->
          res.send data
        .fail (err) ->
          res.status(401).send err

    "auth":

      # Password Resetting
      "get_forgot": (req, res) ->
        res.send """
          <h1>Totally legit password reset page</h1>
          <form method="post" action="#">
            <input name="email" type="email" placeholder="Your email">
            <button>Reset Password</button>
          </form>
        """

      "post_forgot": (req, res) ->
        email = req.body.email
        Auth.generateResetToken(email)
          .then (token) ->
            message = "<h1>Hurrah! We have sent you an email containing a token</h1>"
            link = "<a href=\"http://localhost:5000/api/v0/auth/forgot/#{token}\">Reset Password</a>"

            if DebugMode then return res.send message + "<br><br>" + link

            Mail.send
              to: email
              subject: "Reset Password Token"
              html: link
            res.send message

          .fail (err) ->
            res.status(400).send "#{err}"

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
          return res.status(401).send "err_bad_pass"

        User.checkResetToken(token)
          .then (id) ->

            Q.spread [
              User.get(id)
              Auth.hash(password)
            ], (user, hash) ->
              user.changePassword(hash)
              User.removeResetToken(token)
              res.send "Changed password"
            , (err) ->
              res.status(401).send err


# Bind requests to Express App
bind = (obj, prefix, app) ->
  for key, value of obj
    if (typeof value is "object") and not Array.isArray value
      bind value, "#{prefix}/#{key}", app
    else
      if key.slice(0,4) is "get_"
        app.get "/#{prefix}/#{key.slice(4)}", value
      else if key.slice(0,5) is "post_"
        app.post "/#{prefix}/#{key.slice(5)}", value
bind api, "api", app

# Start Server
server = app.listen(port)

# Start sync
Sync = require "./app/sync"
Sync.init server

module.exports = app
