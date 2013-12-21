  # -----
  # OAuth
  # -----

  'oauth':

    'get_callback': (req, res) ->
      service = req.param('service')
      token = req.param('oauth_token')
      verifier = req.param('oauth_verifier')
      Auth.oauth.verify(service, token, verifier)
      url = 'http://beta.nitrotasks.com'
      res.redirect(301, url)

    'post_request': (req, res) ->
      service = req.body.service
      Auth.oauth.request(service).then (request) ->
        res.send request

    'post_access': (req, res) ->
      service = req.body.service
      request =
        oauth_token: req.body.token
        oauth_token_secret: req.body.secret
      Auth.oauth.access(service, request).then (access) ->
        res.send access

    'post_login': (req, res) ->
      service = req.body.service
      access =
        oauth_token: req.body.token
        oauth_token_secret: req.body.secret
      Auth.oauth.login(service, access)
        .then (data) ->
          res.send data
        .fail (err) ->
          res.status(401).send(err)
