inflection = require 'inflection'

module.exports = class HasOne
  constructor: (@model_type, @key, options_array) ->
    @to_model_type = options_array[0]
    @[key] = value for key, value of options_array[1]
    @foreign_key = inflection.foreign_key(@key) unless @foreign_key

  set: (model, key, value, options, _set) -> _set.call(model, key, value, options)
  get: (model, callback) ->
    # hack
    console.log "HasOne::get foreign_key: #{@foreign_key}"

    related_model_type = @to_model_type
    query = {$one: true}

    if key is @foreign_key
      return callback(null, model.get(foreign_key)) if not @reverse
      query.values = ['id']

    if @reverse
      query[@foreign_key] = model.attributes.id
    else
      query.id = model.get(@foreign_key)

    related_model_type.cursor(query).toModels (err, model) ->
      return callback(err) if err
      return callback(new Error "Model not found. Id #{@foreign_key}") if not model
      callback(null, model)

  type_name: 'hasOne'
