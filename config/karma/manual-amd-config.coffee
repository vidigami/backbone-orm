# Use this config file directly with karma
# karma start ./config/karma/manual_config.coffee

TEST_GROUPS = require '../test_groups'
base_config = require './base-config'

console.log 'NOTE: amd files must already be built!'
module.exports = (config) ->
  config.set(base_config)
  config.set(TEST_GROUPS.amd[0])
  config.set(reporters: ['spec'])
  config.set(basePath: '../..')  # relative to this file
