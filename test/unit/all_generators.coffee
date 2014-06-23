_ = require 'underscore'

try BackboneORM = require 'backbone-orm' catch err then BackboneORM = require('../../backbone-orm')

module.exports = (options, callback) ->
  test_parameters = _.defaults
    database_url: ''
    schema: {}
    sync: BackboneORM.sync
  , options

  require('../generators/all')(test_parameters, callback)
