
module.exports = [

  type: 'get'
  url: '/'
  handler: (req, res) ->
    res.redirect 'http://beta.nitrotasks.com'

]
