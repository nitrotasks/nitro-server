# -----------------------------------------------------------------------------
# Reset Password
# -----------------------------------------------------------------------------

  # Password Resetting
  'get_forgot': (req, res) ->
    res.sendfile('./pages/reset.html')

  'post_forgot': (req, res) ->
    email = req.body.email.toLowerCase()
    Auth.generateResetToken(email)
      .then (token) ->
        link = "<a href=\"#{ config.url }/forgot/#{ token }\">http://#{ config.url }/forgot/#{ token }</a>"
        if DebugMode then return res.send(link)

        Mail.send
          to: email
          subject: 'Nitro Password Reset'
          html: """
            <p>To reset your password, click the link below</p>
            <p>#{link}</p>
            <p>If you did not request your password to be reset, you can just ignore this email and your password will remain the same.</p>
            <p>- Nitrotasks</p>
          """
        res.sendfile('./pages/reset_email.html')

      .fail (err) ->
        if DebugMode then return res.send('error')
        res.status(400).sendfile('./pages/error.html')

  'get_forgot/*': (req, res) ->
    token = req.params[0]
    User.checkResetToken(token)
      .then ->
        res.sendfile('./pages/reset_form.html')
      .fail (err) ->
        if DebugMode then return res.send('error')
        res.sendfile('./pages/error.html')

  'post_forgot/*': (req, res) ->
    password = req.body.password
    confirmation = req.body.passwordConfirmation
    token = req.params[0]

    if password isnt confirmation
      return res.status(401).sendfile('./pages/reset_mismatch.html')

    User.checkResetToken(token)
      .then (id) ->

        Q.spread [
          User.get(id)
          Auth.hash(password)
        ], (user, hash) ->
          user.changePassword(hash)
          User.removeResetToken(token)
          res.sendfile('./pages/reset_success.html')
        , (err) ->
          res.status(401).send err

