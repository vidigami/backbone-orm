util = require 'util'
Backbone = require 'backbone'
inflection = require 'inflection'

module.exports = class HasMany
  constructor: (@model_type, @key, options_array) ->
    @ids_accessor = "#{@key}_ids"
    @related_model_type = options_array[0]
    @[key] = value for key, value of options_array[1]
    @foreign_key = inflection.foreign_key(@key) unless @foreign_key
    # foreign_key: options.foreign_key or @_keyFromTypeAndModel(relation_type, from_model, to_model, options.reverse)
    @collection_type = Backbone.Collection unless @collection_type

  set: (model, key, value, options) ->
    model.attributes[@key] = new @collection_type() unless (model.attributes[@key] instanceof @collection_type)

    console.trace "set value: #{util.inspect(value)}"

    model.attributes[@key].set(value)

  get: (model, key, callback) ->
    # hack
    lookup_key = key.replace('_id', '')
    collection = model.attributes[lookup_key]
    callback(null, if collection then collection.models else []) if callback
    return collection

    query = {}
    query[@foreign_key] = model.attributes.id

    @related_model_type.cursor(query).toModels (err, models) =>
      return callback(err) if err
      return callback(new Error "Model not found. Id #{@foreign_key}") if not models.length
      callback(null, models)