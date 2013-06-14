util = require 'util'
Backbone = require 'backbone'
inflection = require 'inflection'

module.exports = class Many
  constructor: (@model_type, @key, options_array) ->
    @type_name = 'hasMany'
    @ids_accessor = "#{@key}_ids"
    @related_model_type = options_array[0]
    @[key] = value for key, value of options_array[1]
    @foreign_key = inflection.foreign_key(model_type._sync.model_name) unless @foreign_key
    @collection_type = Backbone.Collection unless @collection_type

  set: (model, key, value, options) ->
    # hack
    if key is @ids_accessor
      # TODO

    else
      throw new Error "HasMany::set: Unexpected key #{key}. Expecting: #{@key}" unless key is @key
      throw new Error "HasMany::set: Unexpected type to set #{key}. Expecting array" unless _.isArray(value)
      model.attributes[key] = new @collection_type() unless (model.attributes[key] instanceof @collection_type)
      models = (@findOrCreate(model, key, item) for item in value)
      previous_models = _.clone(collection.models) if reverse_relation = @reverseRelation()

      # set the collection
      collection.set(models)
      return @ unless reverse_relation

      # set the reverses
      for related_model in models
        related_model.set(reverse_key, model) if not reverse_relation.has(related_model, reverse_key, model)

      # clear the reverses
      for related_model in previous_models
        related_model.set(reverse_key, null) if related_model and not collection.find(related_model.get('id'))

    return @

  get: (model, key, callback) ->
    # hack
    if key is @ids_accessor
      relation_key = key.replace('_ids', '')
      related_ids = if related_collection = model.attributes[relation_key] then _.map(related_collection.models, (related_model) -> related_model.get('id')) else []
      callback(null, related_ids) if callback
      return related_ids

    else
      throw new Error "HasMany::get: Unexpected key #{key}. Expecting: #{@key}" unless key is @key
      collection = model.attributes[key]
      callback(null, if collection then collection.models else []) if callback
      return collection

    query = {}
    query[@foreign_key] = model.attributes.id

    @related_model_type.cursor(query).toModels (err, models) =>
      return callback(err) if err
      return callback(new Error "Model not found. Id #{@foreign_key}") if not models.length
      callback(null, models)

  findOrCreate: (model, key, item) ->
    collection = model.attributes[key]
    if item instanceof @related_model_type
      current_related_model = collection.find(item.get('id'))
    else if _.isObject(item)
      current_related_model = collection.find(item.id)
    else
      current_related_model = collection.find(item)
    return current_related_model or @create(item)

  create: (item) ->
    return item if item instanceof @related_model_type
    return new @related_model_type(@related_model_type::parse(item)) if _.isObject(item)
    return new @related_model_type({id: item})

  # TODO: cache
  reverseRelation: (item) ->
    return null if @related_model_type._schema
    reverse_key = inflection.underscore(@model_type.model_name)
    return @related_model_type._schema.relations[reverse_key]
