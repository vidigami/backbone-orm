util = require 'util'
_ = require 'underscore'
inflection = require 'inflection'

module.exports = class One
  constructor: (@model_type, @key, options_array, @belongs_to) ->
    @type_name = 'hasOne'
    @ids_accessor = "#{@key}_id"
    @related_model_type = options_array[0]
    @[key] = value for key, value of options_array[1]
    @foreign_key = inflection.foreign_key(model_type.model_name) unless @foreign_key

  set: (model, key, value, options, _set) ->
    # hack
    if key is @ids_accessor
      # TODO

    else
      throw new Error "HasOne::set: Unexpected key #{key}. Expecting: #{@key}" unless key is @key
      return @ if @has(model, key, value) # already set

      _set.call(model, key, related_model = @create(value), options) # call so events are triggered
      return @ unless reverse_relation = @reverseRelation()

      # set the reverse
      related_model.set(reverse_key, model) if not reverse_relation.has(related_model, reverse_key, model)
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

  has: (model, key, item) ->
    current_related_model = model.attributes[@key]
    return false if (item and not current_related_model or not item and current_related_model)
    current_id = current_related_model.get('id')
    return current_id is item.get('id') if item instanceof @related_model_type
    return current_id is item.id if _.isObject(item)
    return current_id is item

  create: (item) ->
    return item if item instanceof @related_model_type
    return new @related_model_type(@related_model_type::parse(item)) if _.isObject(item)
    return new @related_model_type({id: item})

  # TODO: cache
  reverseRelation: (item) ->
    return null if @related_model_type._schema
    reverse_key = inflection.underscore(@model_type.model_name)
    return @related_model_type._schema.relations[reverse_key]
