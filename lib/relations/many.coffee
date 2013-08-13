util = require 'util'
Backbone = require 'backbone'
_ = require 'underscore'
inflection = require 'inflection'
Queue = require 'queue-async'

Utils = require '../utils'

# @private
module.exports = class Many
  constructor: (@model_type, @key, options) ->
    @[key] = value for key, value of options
    @ids_accessor or= "#{inflection.singularize(@key)}_ids"
    @foreign_key = inflection.foreign_key(@as or @model_type.model_name) unless @foreign_key
    @collection_type = Backbone.Collection unless @collection_type

  initialize: ->
    @reverse_relation = Utils.findOrGenerateReverseRelation(@)
    throw new Error "Both relationship directions cannot embed (#{@model_type.model_name} and #{@reverse_model_type.model_name}). Choose one or the other." if @embed and @reverse_relation and @reverse_relation.embed
    throw new Error "The reverse of a hasMany relation should be `belongsTo`, not `hasOne` (#{@model_type.model_name} and #{@reverse_model_type.model_name})." if @reverse_relation?.type is 'hasOne'

    # check for join table
    @join_table = Utils.findOrGenerateJoinTable(@) if @reverse_relation.type is 'hasMany'

  initializeModel: (model, key) ->
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
      return if key is @ids_accessor then _.map(collection.models, (related_model) -> related_model.id) else collection

    # asynchronous path, needs load
    if callback and not @manual_fetch and not (is_loaded = model.isLoaded(@key))

      # fetch
      (query = {})[@foreign_key] = model.id
      @reverse_model_type.cursor(query).toJSON (err, json) =>
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

  save: (model, key, callback) ->
    return callback() if not @reverse_relation or not @_hasChanged(model)
    delete Utils.orSet(model, 'rel_dirty', {})[@key]
    collection = @_ensureCollection(model)
    use_join = not @reverse_model_type::sync('isRemote') and (@reverse_relation.type is 'hasMany')

    (query = {})[@foreign_key] = model.id
    @reverse_model_type.cursor(query).toJSON (err, json) =>
      return callback(err) if err

      related_models = _.clone(collection.models)
      related_ids = _.pluck(related_models, 'id')
      changes = _.groupBy(json, (test) -> if _.contains(related_ids, test.id) then 'kept' else 'removed')
      added_ids = if changes.added then _.difference(related_ids, (test.id for test in changes.kept)) else related_ids
      queue = new Queue(1)

      # update store through join table
      if use_join
        # destroy removed
        if changes.removed
          do (model_json) => queue.defer (callback) =>
            @join_table.destroy {id: {$in: (model_json.id for model_json in changes.removed)}}, callback

        # create new - TODO: optimize through batch create
        for related_id in added_ids
          do (related_id) => queue.defer (callback) =>
            attributes = {}
            attributes[@foreign_key] = model.id
            attributes[@reverse_relation.foreign_key] = related_id
            # console.log "Creating join for: #{@model_type.model_name} join: #{util.inspect(attributes)}"
            join = new @join_table(attributes)
            join.save {}, Utils.bbCallback callback

      # clear back links on models and save
      else
        # clear removed - TODO: optimize using batch update
        if changes.removed
          for removed_json in changes.removed
            related_model = new @reverse_model_type(removed_json)
            do (related_model) => queue.defer (callback) =>

              if related_collection = related_model.models # collection
                related_collection.remove(found) if found = related_collection.get(model.id)
              else # model
                if found = related_model.get(@reverse_relation.key)
                  found = null unless found.id is model.id
                  related_model.set(@reverse_relation.foreign_key, null) if found
              return callback() unless found # no longer related, skip

              related_model.save {}, Utils.bbCallback (err, saved_model) =>
                cache.set(saved_model.id, saved_model) if not err and cache = @reverse_model_type.cache
                callback(err)

        # add new
        for added_id in added_ids
          related_model = _.find(related_models, (test) -> test.id is added_id)
          do (related_model) => queue.defer (callback) =>
            related_model.save {}, Utils.bbCallback (err, saved_model) =>
              cache.set(saved_model.id, saved_model) if not err and cache = @reverse_model_type.cache
              callback(err)

      queue.await callback

  appendJSON: (json, model, key) ->
    return if key is @ids_accessor # only write the relationships

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
    current_related_model = collection.get(related_model.id)
    throw new Error "Model removed but still exists: #{util.inspect(current_related_model.attributes)}" if current_related_model and current_related_model isnt related_model
    return unless current_related_model
    collection.remove(related_model.id)

  destroy: (model, callback) ->
    return callback() if not @reverse_relation

    collection = @_ensureCollection(model)
    use_join = not @reverse_model_type::sync('isRemote') and (@reverse_relation.type is 'hasMany')

    # clear in memory
    for related_model in _.clone(collection.models)
      related_model.set(@foreign_key, null)
      cache.set(related_model.id, related_model) if cache = related_model.cache() # ensure the cache is up-to-date

    # clear in store through join table
    if use_join
      (query = {})[@foreign_key] = model.attributes.id
      return @join_table.destroy(query, callback)

    # clear back links on models and save
    else
      (query = {})[@foreign_key] = model.id
      @reverse_model_type.cursor(query).toJSON (err, json) =>
        return callback(err) if err

        queue = new Queue(1)

        # clear reverses
        for removed_json in json
          related_model = new @reverse_model_type(removed_json)
          do (related_model) => queue.defer (callback) =>

            if related_collection = related_model.models # collection
              related_collection.remove(found) if found = related_collection.get(model.id)

            else # model
              if found = related_model.get(@foreign_key)
                found = null unless found.id is model.id
                related_model.set(@foreign_key, null) if found
            return callback() unless found # no longer related, skip

            related_model.save {}, Utils.bbCallback (err, saved_model) =>
              cache.set(saved_model.id, saved_model) if not err and cache = @reverse_model_type.cache
              callback(err)

        queue.await callback

  cursor: (model, key, query) ->
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

    # TODO: how should destroying the collection work?
    events = Utils.set(collection, 'events', {})
    events.add = (related_model) =>
      if @reverse_relation.add
        @reverse_relation.add(related_model, model)
      else
        related_model.set(@reverse_relation.key, model) unless related_model.get(@reverse_relation.key) is model

    events.remove = (related_model) =>
      if @reverse_relation.remove
        @reverse_relation.remove(related_model, model)
      else
        related_model.set(@reverse_relation.key, null) unless related_model.get(@reverse_relation.key) is null

    events.reset = (collection, options) =>
      current_models = collection.models
      previous_models = options.previousModels or []

      changes = _.groupBy(previous_models, (test) -> if !!_.find(current_models, (current_model) -> current_model.id is test.id) then 'kept' else 'removed')
      added = if changes.kept then _.select(current_models, (test) -> !!_.find(changes.kept, (keep_model) -> keep_model.id is test.id)) else current_models

      # update back links
      (events.remove(related_model) for related_model in changes.removed) if changes.removed
      (events.add(related_model) for related_model in added)

    collection.on(method, events[method]) for method in ['add', 'remove', 'reset']
    return collection

  _ensureCollection: (model) -> return @_bindBacklinks(model)
  _hasChanged: (model) -> return !!Utils.orSet(model, 'rel_dirty', {})[@key]
