_ = require 'underscore'

module.exports = (options, callback) ->
  test_parameters = _.defaults
    database_url: ''
    schema: {}
    sync: require('../../backbone-orm').sync
  , options

  require('../generators/all')(test_parameters, callback)
