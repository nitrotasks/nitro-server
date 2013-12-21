page = require '../utils/page'

module.exports = [

  type: 'get'
  url: '/*'
  handler: (req, res) ->
    res.status 404
    res.sendfile page '404'

]
