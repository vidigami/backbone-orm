# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  require('./backbone_sync')(options)
  require('./convenience')(options)
  require('./cursor')(options)
  require('./find')(options)
  require('./page')(options)
  require('./sort')(options)
  require('./relation')(options)

  require('./batch_utils')(options)
