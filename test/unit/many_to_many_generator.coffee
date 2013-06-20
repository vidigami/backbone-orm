test_parameters =
  database_url: ''
  schema: {}
  sync: require('../../memory_backbone_sync')
  embed: true

require('../../lib/test_generators/relational/many_to_many')(test_parameters)
