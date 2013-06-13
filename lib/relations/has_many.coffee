Backbone = require 'backbone'
inflection = require 'inflection'

module.exports = class HasMany

  constructor: (@model_type, @key, options_array) ->
    @to_model_type = options_array[0]
    @[key] = value for key, value of options_array[1]
    @foreign_key = inflection.foreign_key(@key) unless @foreign_key
    @collection_type = Backbone.Collection unless @collection_type

  set: (model, key, value, options, _set) ->
    model.attributes[@key] = new @collection_type() unless (model.attributes[@key] instanceof @collection_type)
    model.attributes[@key].set(value)

  get: (model, key, callback) ->

    # hack
    console.log "HasMany::get foreign_key: #{@foreign_key}"
#    foreign_key = @foreign_key.replace('_id', '')
#    return callback(null, model.get(foreign_key).models)

    related_model_type = @to_model_type
    query = {}
    query[@foreign_key] = model.attributes.id

    if key is @foreign_key
      query.values = ['id']

    related_model_type.cursor(query).toModels (err, models) ->
      return callback(err) if err
      return callback(new Error "Model not found. Id #{@foreign_key}") if not models.length
      callback(null, models)

  type_name: 'hasMany'
