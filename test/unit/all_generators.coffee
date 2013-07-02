test_parameters =
  database_url: ''
  schema: {}
  sync: require('../../memory_sync')
  embed: true

require('../generators/all')(test_parameters)
require('../generators/conventions/one')(test_parameters)
require('../generators/conventions/many')(test_parameters)
