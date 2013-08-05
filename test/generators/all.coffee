# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  # require('./all_flat')(options)
  require('./all_relational')(options)
  # require('./conventions/one')(options)
  # require('./conventions/many')(options)
