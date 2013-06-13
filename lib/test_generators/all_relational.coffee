# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  require('./relational/has_one')(options)
  # require('./relational/has_many')(options)
  # require('./relational/many_to_many')(options)
