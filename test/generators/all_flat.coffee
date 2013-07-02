# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  require('./flat/sync')(options)
  require('./flat/batch_utils')(options)
  require('./flat/convenience')(options)
  require('./flat/cursor')(options)
  require('./flat/find')(options)
  require('./flat/page')(options)
  require('./flat/sort')(options)
