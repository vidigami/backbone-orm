test_parameters =
  database_url: ''
  schema: {}
  sync: require('../../memory_backbone_sync')
  embed: true

require('../../lib/test_generators/relational/has_one')(test_parameters)
