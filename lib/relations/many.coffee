util = require 'util'
Backbone = require 'backbone'
_ = require 'underscore'
inflection = require 'inflection'

Utils = require '../../utils'

module.exports = class Many
  constructor: (@model_type, @key, options) ->
    @[key] = value for key, value of options
    @ids_accessor = "#{inflection.singularize(@key)}_ids"
    @foreign_key = inflection.foreign_key(@model_type.model_name) unless @foreign_key
    @collection_type = Backbone.Collection unless @collection_type

  initialize: ->
    @reverse_relation = Utils.reverseRelation(@reverse_model_type, @model_type.model_name) if @model_type.model_name
    throw new Error "Both relationship directions cannot embed (#{@model_type.model_name} and #{@reverse_model_type.model_name}). Choose one or the other." if @embed and @reverse_relation and @reverse_relation.embed

  set: (model, key, value, options) ->
    model.attributes[@key] = new @collection_type() unless (model.attributes[key] instanceof @collection_type)

    # TODO: Allow sql to sync...make a notification? use Backbone.Events?
    key = @key if key is @ids_accessor

    throw new Error "HasMany::set: Unexpected key #{key}. Expecting: #{@key}" unless key is @key
    value = value.models if value instanceof Backbone.Collection
    throw new Error "HasMany::set: Unexpected type to set #{key}. Expecting array: #{util.inspect(value)}" unless _.isArray(value)

    # save previous
    collection = model.attributes[key]
    previous_models = _.clone(collection.models) if @reverse_relation

    # set the collection with found or created models
    collection.reset(models = (collection.get(Utils.dataId(item)) or Utils.createRelated(@reverse_model_type, item) for item in value))
    return @ unless @reverse_relation

    # set ther references
    for related_model in models
      if @reverse_relation.add
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
    model.attributes[@key] = new @collection_type() unless (model.attributes[key] instanceof @collection_type)
    collection = model.attributes[@key]

    # TODO: optimize so don't need to check each time
    # asynchronous path, needs load
    load_ids = []
    for related_model in collection.models
      load_ids.push(related_model.get('id')) if related_model._orm_needs_load
    if load_ids.length
      needs_load = true
      @reverse_model_type.cursor({$ids: load_ids}).toJSON (err, json) =>
        return @reportError(err, callback) if err
        return @reportError(new Error "Failed to load all models. Id #{util.inspect(load_ids)}", callback) if json.length isnt load_ids.length

        # update
        for related_model in collection.models
          if related_model._orm_needs_load
            id = related_model.get('id')
            model_json = _.find(json, (test) -> return test.id is id)
            return @reportError(new Error "Model not found. Id #{id}", callback) if not model_json
            delete related_model._orm_needs_load
            related_model.set(key, model_json)
        @reverse_model_type._cache.markLoaded(collection.models) if @reverse_model_type._cache
        callback(null, if key is @ids_accessor then _.map(collection.models, (test) -> test.get('id')) else collection.models)

    # synchronous path
    if key is @ids_accessor
      related_ids = _.map(collection.models, (related_model) -> related_model.get('id'))
      callback(null, related_ids) if not needs_load and callback
      return related_ids

    else
      throw new Error "HasMany::get: Unexpected key #{key}. Expecting: #{@key}" unless key is @key
      if collection.length
        callback(null, if collection then collection.models else []) if not needs_load and callback
        return collection

    query = {}
    query[@foreign_key] = model.attributes.id

    @reverse_model_type.cursor(query).toModels (err, models) =>
      return if !callback
      return callback(err) if err
      return callback(new Error "Model not found. Id #{@foreign_key}") if not models.length
      callback(null, models)
    return collection

  appendJSON: (json, model, key) ->
    model.attributes[@key] = new @collection_type() unless (model.attributes[key] instanceof @collection_type)

    return if key is @ids_accessor # only write the relationships

    collection = model.attributes[key]
    json_key = if @embed then key else @ids_accessor
    return json[json_key] = if @embed then collection.toJSON() else (model.get('id') for model in collection.models) # TODO: will there ever be nulls?

  has: (model, key, item) ->
    collection = model.attributes[key]
    return !!collection.get(Utils.dataId(item))

  add: (model, item) ->
    collection = model.get(@key)
    return if collection.get(Utils.dataId(item))
    collection.add(Utils.createRelated(@model_type, item))

  remove: (model, item) ->
    collection = model.get(@key)
    collection.remove(Utils.dataId(item))

  reportError: (err, callback) ->
    return callback(err) if callback
    console.log "Many: unhandled error: #{err}. Please supply a callback"

