util = require 'util'
_ = require 'underscore'
inflection = require 'inflection'

Utils = require '../../utils'

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

      # clear reverse
      if reverse_key = Utils.reverseKey(@related_model_type, @model_type)
        current_related_model.set(reverse_key, null) if not @has(model, key, value) and (current_related_model = model.attributes[@key])

      related_model = if value then Utils.createRelated(@related_model_type, value) else null

      _set.call(model, key, related_model, options)
      return @ if not related_model or not reverse_key

      # set the reverse
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

  has: (model, key, item) ->
    return true if not (current_related_model = model.attributes[@key]) and not item
    return false if (current_related_model and not item) or (not current_related_model and item)

    # compare ids
    current_id = current_related_model.get('id')
    return current_id is item.get('id') if item instanceof @related_model_type
    return current_id is item.id if _.isObject(item)
    return current_id is item
