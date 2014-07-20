# Use this config file directly with karma
# karma start ./config/karma/manual_config.coffee

TEST_GROUPS = require '../test_groups'
base_config = require './base-config'

module.exports = (config) ->
  config.set(base_config)
  config.set(TEST_GROUPS.browser_globals[0])
  config.set(basePath: '../..')  # relative to this file
