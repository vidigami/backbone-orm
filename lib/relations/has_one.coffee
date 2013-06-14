util = require 'util'
_ = require 'underscore'
inflection = require 'inflection'

module.exports = class HasOne
  constructor: (@model_type, @key, options_array) ->
    @type_name = 'hasOne'
    @ids_accessor = "#{@key}_id"
    @related_model_type = options_array[0]
    @[key] = value for key, value of options_array[1]
    unless @foreign_key
      @foreign_key = inflection.foreign_key(model_type._sync.model_name)

  set: (model, key, value, options, _set) ->
    # hack
    if key is @ids_accessor
      # TODO

    else
      throw new Error "HasOne::set: Unexpected key #{key}. Expecting: #{@key}" unless key is @key

      # model
      current_related_model = model.attributes[key]
      if value instanceof @related_model_type
        return @ if current_related_model and current_related_model.get('id') is value.get('id') # already exists
        related_model = value

      # data
      else
        if _.isObject(value)
          return @ if current_related_model and current_related_model.get('id') is value.id # already exists
          related_model = new @related_model_type(@related_model_type::parse(value))
        else
          return @ if current_related_model and current_related_model.get('id') is value # already exists
          related_model = new @related_model_type({id: value}) # TODO: need to fetch and look in the cache

      _set.call(model, key, related_model, options) # call so events are triggered

      # set the reverse
      if @related_model_type._schema
        reverse_key = inflection.underscore(@model_type.model_name)
        if reverse_relation = @related_model_type._schema.relations[reverse_key]
          current_model = related_model.get(reverse_key)
          unless (current_model and current_model.get('id') is model.get('id')) # already set
            related_model.set(reverse_key, model)
    return @

  get: (model, key, callback, _get) ->
    # hack
    if key is @ids_accessor
      relation_key = key.replace('_id', '')
      related_id = if related_model = model.attributes[relation_key] then related_model.get('id') else undefined
      callback(null, related_id) if callback
      return related_id

    else
      throw new Error "HasOne::get: Unexpected key #{key}. Expecting: #{@key}" unless key is @key
      value = model.attributes[key]
      callback(null, value) if callback
      return value

    query = {$one: true}
    query[@foreign_key] = model.attributes.id

    @related_model_type.cursor(query).toModels (err, model) =>
      return callback(err) if err
      return callback(new Error "Model not found. Id #{@foreign_key}") if not model
      callback(null, model)
