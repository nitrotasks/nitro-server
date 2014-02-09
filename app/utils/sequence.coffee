Promise = require 'bluebird'

module.exports = (array, fn) ->
  Promise.reduce(array, ((_, item) -> fn(item)), null)