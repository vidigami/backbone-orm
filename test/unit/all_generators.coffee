module.exports = (options, callback) ->
  test_parameters =
    database_url: ''
    schema: {}
    sync: require('../../memory_sync')
    embed: true

  require('../generators/all')(test_parameters, callback)
