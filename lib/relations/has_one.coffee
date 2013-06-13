util = require 'util'
_ = require 'underscore'
inflection = require 'inflection'

module.exports = class HasOne
  constructor: (@model_type, @key, options_array) ->
    @ids_accessor = "#{@key}_id"
    @related_model_type = options_array[0]
    @[key] = value for key, value of options_array[1]
    @foreign_key = inflection.foreign_key(@key) unless @foreign_key
    # foreign_key: options.foreign_key or @_keyFromTypeAndModel(relation_type, from_model, to_model, options.reverse)

  set: (model, key, value, options, _set) ->
    unless value instanceof @related_model_type
      if _.isObject(value)
        value = new @related_model_type(@related_model_type::parse(value))
      else
        value = new @related_model_type(@related_model_type::parse({id: value})) # TODO: need to fetch

    _set.call(model, key, value, options)

  get: (model, key, callback, _get) ->
    # hack
    if key is @ids_accessor
      related_id = if related_model = model.attributes[key.replace('_id', '')] then related_model.get('id') else undefined
      callback(null, related_id) if callback
      return related_id

    else
      callback(null, model.attributes[key]) if callback
      return model.attributes[key]

    query = {$one: true}

    # if @reverse
    #   query[@foreign_key] = model.attributes.id
    # else
    query.id = model.get(@foreign_key)

    @related_model_type.cursor(query).toModels (err, model) =>
      return callback(err) if err
      return callback(new Error "Model not found. Id #{@foreign_key}") if not model
      callback(null, model)
