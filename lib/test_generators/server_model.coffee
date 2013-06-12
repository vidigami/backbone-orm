# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  require('../../lib/test_generators/backbone_sync')(options)
  require('../../lib/test_generators/convenience')(options)
  require('../../lib/test_generators/cursor')(options)
  require('../../lib/test_generators/find')(options)
  require('../../lib/test_generators/page')(options)
  require('../../lib/test_generators/sort')(options)
  require('../../lib/test_generators/relation')(options)
