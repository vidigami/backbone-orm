util = require 'util'
Backbone = require 'backbone'
_ = require 'underscore'
inflection = require 'inflection'
Queue = require 'queue-async'

Utils = require '../utils'

# @private
module.exports = class Many extends require('./relation')
  constructor: (@model_type, @key, options) ->
    @[key] = value for key, value of options
    @ids_accessor or= "#{inflection.singularize(@key)}_ids"
    @join_key = inflection.foreign_key(@model_type.model_name) unless @join_key
    @foreign_key = inflection.foreign_key(@as or @model_type.model_name) unless @foreign_key
    @collection_type = Backbone.Collection unless @collection_type

  initialize: ->
    @reverse_relation = @_findOrGenerateReverseRelation(@)
    throw new Error "Both relationship directions cannot embed (#{@model_type.model_name} and #{@reverse_model_type.model_name}). Choose one or the other." if @embed and @reverse_relation and @reverse_relation.embed
    throw new Error "The reverse of a hasMany relation should be `belongsTo`, not `hasOne` (#{@model_type.model_name} and #{@reverse_model_type.model_name})." if @reverse_relation?.type is 'hasOne'

    # check for join table
    @join_table = @findOrGenerateJoinTable(@) if @reverse_relation.type is 'hasMany'

  initializeModel: (model) ->
    model.setLoaded(@key, false)
    @_bindBacklinks(model)

  set: (model, key, value, options) ->
    throw new Error "Many::set: Unexpected key #{key}. Expecting: #{@key} or #{@ids_accessor}" unless (key is @key or key is @ids_accessor)
    collection = @_bindBacklinks(model)

    value = value.models if value instanceof Backbone.Collection
    value = [] if _.isUndefined(value) # Backbone clear or reset
    throw new Error "HasMany.set: Unexpected type to set #{key}. Expecting array: #{util.inspect(value)}" unless _.isArray(value)

    Utils.orSet(model, 'rel_dirty', {})[@key] = true
    model.setLoaded(@key, true)

    # set the collection with found or created models
    models = ((if related_model = collection.get(Utils.dataId(item)) then Utils.updateModel(related_model, item) else Utils.updateOrNew(item, @reverse_model_type)) for item in value)
    previous_models = _.clone(collection.models)
    collection.reset(models)

    if @reverse_relation.type is 'belongsTo'
      model_ids = _.pluck(models, 'id')
      related_model.set(@foreign_key, null) for related_model in previous_models when not _.contains(model_ids, related_model.id)

    return @

  get: (model, key, callback) ->
    throw new Error "Many::get: Unexpected key #{key}. Expecting: #{@key} or #{@ids_accessor}" unless (key is @key or key is @ids_accessor)
    collection = @_ensureCollection(model)
    returnValue = =>
      return if key is @ids_accessor then (related_model.id for related_model in collection.models) else collection

    # asynchronous path, needs load
    if callback and not @manual_fetch and not (is_loaded = model.isLoaded(@key))
      # fetch
      @cursor(model, @key).toJSON (err, json) =>
        return callback(err) if err
        model.setLoaded(@key, true)

        # process the found models
        for model_json in json
          if related_model = collection.get(model_json.id)
            related_model.set(model_json)
          else
            collection.add(related_model = Utils.updateOrNew(model_json, @reverse_model_type))

        # update cache
        (cache.set(model.id, related_model) for related_model in collection.models) if cache = @reverse_model_type.cache

        result = returnValue()
        callback(null, if result.models then result.models else result)

    # synchronous path
    result = returnValue()
    callback(null, if result.models then result.models else result) if callback and (is_loaded or @manual_fetch)
    return result

  save: (model, callback) ->
    return callback() if not @_hasChanged(model)
    delete Utils.orSet(model, 'rel_dirty', {})[@key]
    collection = @_ensureCollection(model)
    @_saveRelated(model, _.clone(collection.models), callback)

  appendJSON: (json, model, key) ->
    return if key is @ids_accessor # only write the relationships
    return if @isVirtual() # skip virtual attributes

    collection = @_ensureCollection(model)
    json_key = if @embed then key else @ids_accessor
    return json[json_key] = collection.toJSON() if @embed

  add: (model, related_model) ->
    collection = @_ensureCollection(model)
    current_related_model = collection.get(related_model.id)
    return if current_related_model is related_model
    throw new Error "\nModel added twice: #{util.inspect(current_related_model)}\nand\n#{util.inspect(related_model)}" if current_related_model
    collection.add(related_model)

  remove: (model, related_model) ->
    collection = @_ensureCollection(model)
    return unless current_related_model = collection.get(related_model.id)
    collection.remove(current_related_model)

  destroy: (model, callback) ->
    return callback() if not @reverse_relation
    if model instanceof Backbone.Model
      delete Utils.orSet(model, 'rel_dirty', {})[@key]
      collection = @_ensureCollection(model)
      related_models = _.clone(collection.models)
    else
      related_models = (new @reverse_model_type(json) for json in (model[@key] or []))

    # clear in memory
    for related_model in related_models
      related_model.set(@foreign_key, null)
      cache.set(related_model.id, related_model) if cache = related_model.cache() # ensure the cache is up-to-date

    # clear in store through join table
    (query = {})[@foreign_key] = model.id
    return @join_table.destroy(query, callback) if @join_table

    # clear back links on models and save
    (query = {})[@foreign_key] = model.id
    @reverse_model_type.cursor(query).toJSON (err, json) =>
      return callback(err) if err

      # clear reverses
      queue = new Queue(1)
      for related_json in json
        do (related_json) => queue.defer (callback) => @_clearAndSaveRelatedBacklink(model, related_json, callback)
      queue.await callback

  cursor: (model, key, query) ->
    # return VirtualCursor(query, {model: model, relation: @}) if @manual_fetch # TODO: need to write tests and generalize the checks isFetchable

    json = if model instanceof Backbone.Model then model.attributes else model
    (query = _.clone(query or {}))[@foreign_key] = json.id
    (query.$values or= []).push('id') if key is @ids_accessor
    return @reverse_model_type.cursor(query)

  ####################################
  # Internal
  ####################################
  _bindBacklinks: (model) ->
    return collection if ((collection = model.attributes[@key]) instanceof @collection_type)
    collection = model.attributes[@key] = new @collection_type()
    return collection unless @reverse_relation # no back links

    events = Utils.set(collection, 'events', {})
    events.add = (related_model) =>
      if @reverse_relation.add
        @reverse_relation.add(related_model, model)
      else
        current_model = related_model.get(@reverse_relation.key)
        is_current = Utils.dataId(current_model) is model.id
        related_model.set(@reverse_relation.key, model) if not is_current or (is_current and not current_model.isLoaded())

    events.remove = (related_model) =>
      if @reverse_relation.remove
        @reverse_relation.remove(related_model, model)
      else
        current_model = related_model.get(@reverse_relation.key)
        related_model.set(@reverse_relation.key, null) if Utils.dataId(current_model) is model.id

    events.reset = (collection, options) =>
      current_models = collection.models
      previous_models = options.previousModels or []
      changes = _.groupBy(previous_models, (test) -> if !!_.find(current_models, (current_model) -> current_model.id is test.id) then 'kept' else 'removed')
      added = if changes.kept then _.select(current_models, (test) -> !_.find(changes.kept, (keep_model) -> keep_model.id is test.id)) else current_models

      # update back links
      (events.remove(related_model) for related_model in changes.removed) if changes.removed
      (events.add(related_model) for related_model in added)

    # TODO: how to unbind
    collection.on(method, events[method]) for method in ['add', 'remove', 'reset'] # bind

    return collection

  _ensureCollection: (model) -> return @_bindBacklinks(model)
  _hasChanged: (model) ->
    return !!Utils.orSet(model, 'rel_dirty', {})[@key] or model.hasChanged(@key)
    return false unless @reverse_relation
    collection = @_ensureCollection(model)
    return true for model in model.models when model.hasChanged(@reverse_relation.foreign_key)
    return false
