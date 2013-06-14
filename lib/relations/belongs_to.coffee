util = require 'util'
_ = require 'underscore'
inflection = require 'inflection'

module.exports = class BelongsTo
  constructor: (@model_type, @key, options_array) ->
    @type_name = 'belongsTo'
    @ids_accessor = "#{@key}_id"
    @related_model_type = options_array[0]
    @[key] = value for key, value of options_array[1]
    unless @foreign_key
      @foreign_key = inflection.foreign_key(@key)

  set: (model, key, value, options, _set) ->
    # hack
    if key is @ids_accessor
      # TODO

    else
      throw new Error "BelongsTo::set: Unexpected key #{key}. Expecting: #{@key}" unless key is @key
      unless value instanceof @related_model_type
        if _.isObject(value)
          value = new @related_model_type(@related_model_type::parse(value))
        else
          value = new @related_model_type(@related_model_type::parse({id: value})) # TODO: need to fetch

      _set.call(model, key, value, options)

  get: (model, key, callback, _get) ->
    # hack
    if key is @ids_accessor
      relation_key = key.replace('_id', '')
      related_id = if related_model = model.attributes[relation_key] then related_model.get('id') else undefined
      callback(null, related_id) if callback
      return related_id

    else
      throw new Error "BelongsTo::get: Unexpected key #{key}. Expecting: #{@key}" unless key is @key
      value = model.attributes[key]
      callback(null, value) if callback
      return value

    query =
      $one: true
      id: model.get(@foreign_key)

    @related_model_type.cursor(query).toModels (err, model) =>
      return callback(err) if err
      return callback(new Error "Model not found. Id #{@foreign_key}") if not model
      callback(null, model)
