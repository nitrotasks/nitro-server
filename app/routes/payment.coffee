  # ------------------
  # PayPal integration
  # ------------------

  # Return the pro status of a user
  'get_pro': (req, res) ->
    uid = req.param('uid')
    # code = req.body.code
    User.get(uid)
      .then (user) ->
        user.changeProStatus(1)
        res.end()
      .fail ->
        res.status(400).send('err')
