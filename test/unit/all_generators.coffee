_ = require 'underscore'

module.exports = (options, callback) ->
  test_parameters = _.defaults
    database_url: ''
    schema: {}
    sync: require('../../lib/memory/sync')
  , options

  require('../generators/all')(test_parameters, callback)
