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
    if @reverse_relation.type is 'hasMany' and not @join_table
      if @reverse_relation.join_table
        @join_table = @reverse_relation.join_table
      else
        @join_table = Utils.createJoinTableModel(@)

  initializeModel: (model, key) ->
    @_setLoaded(model, false)
    @_bindBacklinks(model)

  set: (model, key, value, options) ->
    throw new Error "Many::set: Unexpected key #{key}. Expecting: #{@key} or #{@ids_accessor}" unless (key is @key or key is @ids_accessor)
    collection = @_ensureCollection(model)

    value = value.models if value instanceof Backbone.Collection
    value = [] if _.isUndefined(value) # Backbone clear or reset
    throw new Error "HasMany::set: Unexpected type to set #{key}. Expecting array: #{util.inspect(value)}" unless _.isArray(value)

    # set the collection with found or created models
    models = []
    for item in value
      if related_model = collection.get(Utils.dataId(item))
        Utils.updateModel(model, item)
      else
        related_model = Utils.updateOrNew(item, @reverse_model_type)
      models.push(related_model)

    if @reverse_relation.type is 'belongsTo'
      for related_model in collection.models when related_model.id not in _.pluck(models, 'id')
        related_model.set(@foreign_key, null)
        #todo: is this necessary?
        if cache = @reverse_model_type.cache()
          cache.set(related_model.id, related_model)
        @_queueDependentSave(model, related_model.id)

    collection.reset(models)
    @_setLoaded(model, true)

    return @

  get: (model, key, callback) ->
    throw new Error "Many::get: Unexpected key #{key}. Expecting: #{@key} or #{@ids_accessor}" unless (key is @key or key is @ids_accessor)
    returnValue = =>
      collection = @_ensureCollection(model)
      return if key is @ids_accessor then _.map(collection.models, (related_model) -> related_model.id) else collection

    # asynchronous path, needs load
    if not @manual_fetch and callback
      is_loaded = @_fetchRelated model, key, (err) =>
        return callback(err) if err
        result = returnValue()
        callback(null, if result.models then result.models else result)

    # synchronous path
    result = returnValue()
    callback(null, if result.models then result.models else result) if (is_loaded or @manual_fetch) and callback
    return result

  save: (model, key, callback) ->
    return callback() if not @reverse_relation or not (related_model = model.attributes[@key])

    if @reverse_relation.type is 'belongsTo'

      # collection
      if related_models = related_model.models
        queue = new Queue(1) # TODO: parallelism

        for related_model in related_models when (related_model.hasChanged(@reverse_relation.key) or not related_model.id)
          do (related_model) => queue.defer (callback) => related_model.save {}, Utils.bbCallback callback

        if dependent_ids = model._orm.dependent_saves?[@key]
          queue.defer (callback) =>
            # Update foreign keys of relations that should no longer point to this model
            (query = {})[@foreign_key] = model.attributes.id
            @reverse_model_type.cursor({$ids: dependent_ids}).toModels (err, attached_models) =>
              @_clearHasOneRelatedModels(attached_models, callback)
              @_clearDependentSaves(model)

        return queue.await callback

      # model
      else
        return related_model.save {}, Utils.bbCallback callback if related_model.hasChanged(@reverse_relation.key) or not related_model.id

    # hasMany
    else
      collection = @_ensureCollection(model)
      return callback() unless @_isLoaded(model) # not loaded

      # TODO: optimize
      query = {$values: @foreign_key}
      query[@foreign_key] = model.id
      @join_table.cursor(query).toJSON (err, json) =>
        return callback(err) if err

        related_ids = _.pluck(collection.models, 'id')
        changes = _.groupBy(json, (test) -> if _.contains(related_ids, test.id) then 'kept' else 'removed')
        added = if changes.kept then _.difference(related_ids, changes.kept) else related_ids

        queue = new Queue(1) # TODO: parallelism

        # destroy old
        if changes.removed
          for model_json in changes.removed
            # TODO: optimize
            do (model_json) => queue.defer (callback) =>
              # console.log "Destroying join for: #{@model_type.model_name} join: #{util.inspect(model_json)}"
              @join_table.destroy model_json.id, callback

        # create new
        for related_id in added
          do (related_id) => queue.defer (callback) =>
            attributes = {}
            attributes[@foreign_key] = model.id
            attributes[@reverse_relation.foreign_key] = related_id
            # console.log "Creating join for: #{@model_type.model_name} join: #{util.inspect(attributes)}"
            join = new @join_table(attributes)
            join.save {}, Utils.bbCallback callback

        queue.await callback
      return

    # nothing to save
    callback()

  appendJSON: (json, model, key) ->
    return if key is @ids_accessor # only write the relationships

    collection = @_ensureCollection(model)
    json_key = if @embed then key else @ids_accessor
    return json[json_key] = collection.toJSON() if @embed

  # TODO: review for multiple instances, eg. same id
  has: (model, key, data) -> return !!@_ensureCollection(model).get(Utils.dataId(data))

  add: (model, related_model) ->
    collection = @_ensureCollection(model)
    current_related_model = collection.get(related_model.id)
    return if current_related_model is related_model
    throw new Error "\nModel added twice: #{util.inspect(current_related_model)}\nand\n#{util.inspect(related_model)}" if current_related_model
    collection.add(related_model)

##todo: update isLoaded when adding / removing
  remove: (model, related_model) ->
    collection = @_ensureCollection(model)
    current_related_model = collection.get(related_model.id)
    throw new Error "Model removed but still exists: #{util.inspect(current_related_model.attributes)}" if current_related_model and current_related_model isnt related_model
    return unless current_related_model
    collection.remove(related_model.id)

  destroy: (model, callback) ->
    return callback() if not @reverse_relation
    return @_clearRelation(model, callback)

  cursor: (model, key, query) ->
    json = if model instanceof Backbone.Model then model.attributes else model
    (query = _.clone(query or {}))[@foreign_key] = json.id
    (query.$values or= []).push('id') if key is @ids_accessor
    return (@join_table or @reverse_model_type).cursor(query)

  ####################################
  # Internal
  ####################################

  _setLoaded: (model, loaded) ->
    if loaded
      delete model._orm?.needs_load?[@key]
    else
      model._orm or= {}
      (model._orm.needs_load or= {})[@key] = true

  _isLoaded: (model) ->
    return not model._orm.needs_load?[@key]

  _queueDependentSave: (model, id) ->
    model._orm or= {}
    (model._orm.dependent_saves or= {})[@key] or= []
    model._orm.dependent_saves[@key].push(id)

  _clearDependentSaves: (model) ->
    delete model._orm?.dependent_saves?[@key]

  # TODO: ensure initialize is called only once and only from initializeModel
  _ensureCollection: (model) -> @_bindBacklinks(model)

  _bindBacklinks: (model) ->
    return collection if ((collection = model.attributes[@key]) instanceof @collection_type)
    collection = model.attributes[@key] = new @collection_type()
    return collection unless @reverse_relation # no back links

    # TODO: how should destroying the collection work?
    collection._orm_bindings = {}
    collection._orm_bindings.add = (related_model) =>
      if @reverse_relation.add
        @reverse_relation.add(related_model, model)
      else
        related_model.set(@reverse_relation.key, model) unless related_model.attributes[@reverse_relation.key] is model

    collection._orm_bindings.remove = (related_model) =>
      if @reverse_relation.remove
        @reverse_relation.remove(related_model, model)
      else
        related_model.set(@reverse_relation.key, null) unless related_model.attributes[@reverse_relation.key] is null

    collection._orm_bindings.reset = (collection, options) =>
      current_models = collection.models
      previous_models = options.previousModels or []

      changes = _.groupBy(previous_models, (test) -> if !!_.find(current_models, (current_model) -> current_model.id is test.id) then 'kept' else 'removed')
      added = if changes.kept then _.select(current_models, (test) -> !!_.find(changes.kept, (keep_model) -> keep_model.id is test.id)) else current_models

      # update back links
      (collection._orm_bindings.remove(related_model) for related_model in changes.removed) if changes.removed
      (collection._orm_bindings.add(related_model) for related_model in added)

    collection.on(method, collection._orm_bindings[method]) for method in ['add', 'remove', 'reset']
    return collection

  # TODO: optimize so don't need to check each time
  _fetchRelated: (model, key, callback) ->
    return true if @_isLoaded(model, key) # already loaded
    collection = @_ensureCollection(model)

    # TODO: check which objects are already loaded in cache and ignore ids

    # fetch
    (query = {})[@foreign_key] = model.id
    (@join_table or @reverse_model_type).cursor(query).toJSON (err, json) =>

      return callback(err) if err

      # process the found models
      for model_json in json

        # update existing
        if related_model = collection.get(model_json.id)
          related_model.set(model_json)

        # create new
        else
          collection.add(related_model = Utils.updateOrNew(model_json, @reverse_model_type))

      if cache = @reverse_model_type.cache()
        cache.set(model.id, model) for model in collection.models

      @_setLoaded(model, true)

      callback(null, collection.models)
    return false

  _clearRelation: (model, callback) ->
    (query = {})[@foreign_key] = model.attributes.id
    if @reverse_relation.type is 'hasMany'
      @join_table.destroy query, (err, json) =>
        callback()
    else
      if (collection = @_ensureCollection(model))?.length
        @_clearHasOneRelatedModels(collection.models, callback)
      else
        @cursor(model, @key).toModels (err, related_models) =>
          return callback(err) if err
          @_clearHasOneRelatedModels(related_models, callback)

  _clearHasOneRelatedModels: (related_models, callback) ->
    return callback() unless related_models.length
    (update = {})[@foreign_key] = null
    queue = new Queue()
    for related_model in related_models
      if related_model
        do (related_model) =>
          queue.defer (callback) =>
            related_model.save update, Utils.bbCallback (err, saved_model) =>
              callback(err) if err
              if cache = @reverse_model_type.cache()
                cache.set(saved_model.id, saved_model)
              callback()
    queue.await callback
