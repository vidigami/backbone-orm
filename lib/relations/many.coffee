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
    collection = @ensureCollection(model, key)

    # TODO: Allow sql to sync...make a notification? use Backbone.Events?
    key = @key if key is @ids_accessor

    throw new Error "HasMany::set: Unexpected key #{key}. Expecting: #{@key}" unless key is @key
    value = value.models if value instanceof Backbone.Collection
    throw new Error "HasMany::set: Unexpected type to set #{key}. Expecting array: #{util.inspect(value)}" unless _.isArray(value)

    # save previous
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
    # asynchronous path, needs load
    needs_load = !!@_fetchRelated model, key, (err, models) =>
      return @_reportError(err, callback) if err
      callback(null, if key is @ids_accessor then _.map(models, (test) -> test.get('id')) else models)

    # synchronous path
    collection = @ensureCollection(model, key)
    if key is @ids_accessor
      related_ids = _.map(collection.models, (related_model) -> related_model.get('id'))
      callback(null, related_ids) if not needs_load and callback
      return related_ids
    else
      throw new Error "HasMany::get: Unexpected key #{key}. Expecting: #{@key}" unless key is @key
      callback(null, collection.models) if not needs_load and callback
      return collection

  appendJSON: (json, model, key) ->
    return if key is @ids_accessor # only write the relationships

    collection = @ensureCollection(model, key)
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

  _reportError: (err, callback) ->
    return callback(err) if callback
    console.log "Many: unhandled error: #{err}. Please supply a callback"

  ensureCollection: (model, key) ->
    model.attributes[@key] = new @collection_type() unless (model.attributes[key] instanceof @collection_type)
    return model.attributes[@key]

  # TODO: optimize so don't need to check each time
  _fetchRelated: (model, key, callback) ->
    collection = @ensureCollection(model, key)

    # collect ids to load
    load_ids = []
    for related_model in collection.models
      continue unless related_model._orm_needs_load
      throw new Error "Missing id for load" unless id = related_model.get('id')
      load_ids.push(id)
    return 0 unless load_ids.length

    # fetch
    @reverse_model_type.cursor({$ids: load_ids}).toJSON (err, json) =>
      return callback(err) if err
      return callback(new Error "Failed to load all models. Id #{util.inspect(load_ids)}", callback) if json.length isnt load_ids.length

      # update
      for related_model in collection.models
        if related_model._orm_needs_load
          id = related_model.get('id')
          model_json = _.find(json, (test) -> return test.id is id)
          return @_reportError(new Error "Model not found. Id #{id}", callback) if not model_json
          delete related_model._orm_needs_load
          related_model.set(key, model_json)

      @reverse_model_type._cache.markLoaded(collection.models) if @reverse_model_type._cache
      callback(null, collection.models)

    return load_ids.length