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
    @foreign_key = inflection.foreign_key(model_type.model_name) unless @foreign_key
    @collection_type = Backbone.Collection unless @collection_type
    @reverse_relation = Utils.reverseRelation(@related_model_type, @model_type)

  set: (model, key, value, options) ->
    # console.log "SET key: #{key} value: #{util.inspect(value)}"

    # hack
    if key is @ids_accessor
      # TODO

    else
      throw new Error "HasMany::set: Unexpected key #{key}. Expecting: #{@key}" unless key is @key
      value = value.models if value instanceof Backbone.Collection
      throw new Error "HasMany::set: Unexpected type to set #{key}. Expecting array: #{util.inspect(value)}" unless _.isArray(value)
      model.attributes[key] = new @collection_type() unless (model.attributes[key] instanceof @collection_type)
      models = (@findOrCreate(model, item) for item in value)
      collection = model.attributes[key]

      console.log "key: #{key}"

      # save previous
      previous_models = _.clone(collection.models) if @reverse_relation

      # set the collection
      collection.reset(models)
      return @ unless @reverse_relation

      # set ther references
      for related_model in models
        if @reverse_relation.add
          # console.log "Setting reverse #{@reverse_relation.key}: #{util.inspect(model.attributes)}"

          @reverse_relation.add(related_model, model)
        else
          related_model.set(@reverse_relation.key, model)

      # clear the reverses
      for related_model in previous_models
        continue if not related_model or collection.get(related_model.get('id'))

        if @reverse_relation.remove
          @reverse_relation.remove(related_model, model)
        else
          related_model.set(@reverse_relation.key, null)

    return @

  get: (model, key, callback) ->
    # hack
    if key is @ids_accessor
      relation_key = key.replace('_ids', '')
      related_ids = if related_collection = model.attributes[relation_key] then _.map(related_collection.models, (related_model) -> related_model?.get('id')) else []
      callback(null, related_ids) if callback
      return related_ids

    else
      throw new Error "HasMany::get: Unexpected key #{key}. Expecting: #{@key}" unless key is @key
      model.attributes[key] = new @collection_type() unless (model.attributes[key] instanceof @collection_type)
      collection = model.attributes[key]
      callback(null, if collection then collection.models else []) if callback
      return collection

    query = {}
    query[@foreign_key] = model.attributes.id

    @related_model_type.cursor(query).toModels (err, models) =>
      return callback(err) if err
      return callback(new Error "Model not found. Id #{@foreign_key}") if not models.length
      callback(null, models)

  findOrCreate: (model, item) ->
    collection = model.attributes[@key]
    return collection.get(Utils.itemId(item)) or Utils.createRelated(@model_type, item)

  itemId: (model, item) ->

  add: (model, item) ->
    collection = model.get(@key)
    item = @findOrCreate(model, item)
    return if collection.get(item.get('id'))
    collection.add(item)

  remove: (model, item) ->
    collection = model.get(@key)
    collection.remove(item)
