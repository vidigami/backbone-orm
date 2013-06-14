util = require 'util'
Backbone = require 'backbone'
_ = require 'underscore'
inflection = require 'inflection'

Utils = require '../../utils'

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
      collection = model.attributes[key]
      previous_models = _.clone(collection.models) if reverse_key = Utils.reverseKey(@related_model_type, @model_type)

      # set the collection
      collection.set(models)
      return @ unless reverse_key

      # set the reverses
      related_model.set(reverse_key, model) for related_model in models

      # clear the reverses
      for related_model in previous_models
        related_model.set(reverse_key, null) if related_model and not collection.get(related_model.get('id'))

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
      id = item.get('id')
    else if _.isObject(item)
      id = item.id
    else
      id = item
    return collection.get(id) or Utils.createRelated(@model_type, item)
