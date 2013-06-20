test_parameters =
  database_url: ''
  schema: {}
  sync: require('../../memory_backbone_sync')
  embed: true

require('../generators/all')(test_parameters)
