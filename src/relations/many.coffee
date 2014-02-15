###
  backbone-orm.js 0.5.10
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js, Underscore.js, Moment.js, and Inflection.js.
###

Backbone = require 'backbone'
_ = require 'underscore'
inflection = require 'inflection'

Queue = require '../queue'
Utils = require '../utils'

# @private
module.exports = class Many extends require('./relation')
  constructor: (@model_type, @key, options) ->
    @[key] = value for key, value of options
    @virtual_id_accessor or= "#{inflection.singularize(@key)}_ids"
    @join_key = @foreign_key or inflection.foreign_key(@model_type.model_name) unless @join_key
    @foreign_key = inflection.foreign_key(@as or @model_type.model_name) unless @foreign_key
    unless @collection_type
      # @private
      class Collection extends Backbone.Collection
        model: @reverse_model_type
      @collection_type = Collection

  initialize: ->
    @reverse_relation = @_findOrGenerateReverseRelation(@)
    throw new Error "Both relationship directions cannot embed (#{@model_type.model_name} and #{@reverse_model_type.model_name}). Choose one or the other." if @embed and @reverse_relation and @reverse_relation.embed
    throw new Error "The reverse of a hasMany relation should be `belongsTo`, not `hasOne` (#{@model_type.model_name} and #{@reverse_model_type.model_name})." if @reverse_relation?.type is 'hasOne'

    # check for join table
    @join_table = @findOrGenerateJoinTable(@) if @reverse_relation.type is 'hasMany'

  initializeModel: (model) ->
    model.setLoaded(@key, false) unless model.isLoadedExists(@key) # it may have been set before initialize is called
    @_bindBacklinks(model)

  releaseModel: (model) ->
    @_unbindBacklinks(model)
    delete model._orm

  set: (model, key, value, options) ->
    throw new Error "Many.set: Unexpected key #{key}. Expecting: #{@key} or #{@virtual_id_accessor} or #{@foreign_key}" unless ((key is @key) or (key is @virtual_id_accessor) or (key is @foreign_key))
    collection = @_bindBacklinks(model)

    value = value.models if Utils.isCollection(value)
    value = [] if _.isUndefined(value) # Backbone clear or reset
    throw new Error "HasMany.set: Unexpected type to set #{key}. Expecting array: #{Utils.inspect(value)}" unless _.isArray(value)

    Utils.orSet(model, 'rel_dirty', {})[@key] = true
    model.setLoaded(@key, _.all(value, (item) -> Utils.dataId(item) isnt item))

    # set the collection with found or created models
    models = ((if related_model = collection.get(Utils.dataId(item)) then Utils.updateModel(related_model, item) else Utils.updateOrNew(item, @reverse_model_type)) for item in value)
    model.setLoaded(@key, _.all(models, (model) -> model.isLoaded()))
    previous_models = _.clone(collection.models)
    collection.reset(models)

    if @reverse_relation.type is 'belongsTo'
      model_ids = _.pluck(models, 'id')
      related_model.set(@foreign_key, null) for related_model in previous_models when not _.contains(model_ids, related_model.id)

    return @

  get: (model, key, callback) ->
    throw new Error "Many.get: Unexpected key #{key}. Expecting: #{@key} or #{@virtual_id_accessor} or #{@foreign_key}" unless ((key is @key) or (key is @virtual_id_accessor) or (key is @foreign_key))
    collection = @_ensureCollection(model)
    returnValue = =>
      return if key is @virtual_id_accessor then (related_model.id for related_model in collection.models) else collection

    # asynchronous path, needs load
    if callback and not @isVirtual() and not @manual_fetch and not (is_loaded = model.isLoaded(@key))
      # fetch
      @cursor(model, @key).toJSON (err, json) =>
        return callback(err) if err
        model.setLoaded(@key, true)

        # process the found models
        for model_json in json
          if related_model = collection.get(model_json[@reverse_model_type::idAttribute])
            related_model.set(model_json)
          else
            collection.add(related_model = Utils.updateOrNew(model_json, @reverse_model_type))

        # update cache
        (cache.set(related_model.id, related_model) for related_model in collection.models) if cache = @reverse_model_type.cache

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

  appendJSON: (json, model) ->
    return if @isVirtual() # skip virtual attributes

    collection = @_ensureCollection(model)
    json_key = if @embed then @key else @virtual_id_accessor
    return json[json_key] = collection.toJSON() if @embed

  add: (model, related_model) ->
    collection = @_ensureCollection(model)
    current_related_model = collection.get(related_model.id)
    return if current_related_model is related_model

    # TODO: this is needed for model lifecycle - not knowing when a model is actually disposed and not wanting to remove a model from a relationship
    # throw new Error "\nModel added twice: #{Utils.inspect(current_related_model)}\nand\n#{Utils.inspect(related_model)}" if current_related_model
    collection.remove(current_related_model) if current_related_model
    @reverse_model_type.cache.set(related_model.id, related_model) if @reverse_model_type.cache and related_model.id # make sure the latest model is in the cache
    collection.add(related_model)

  remove: (model, related_model) ->
    collection = @_ensureCollection(model)
    return unless current_related_model = collection.get(related_model.id)
    collection.remove(current_related_model)

  patchAdd: (model, relateds, callback) ->
    return callback(new Error "Many.patchAdd: model has null id for: #{@key}") unless model.id
    return callback(new Error "Many.patchAdd: missing model for: #{@key}") unless relateds

    relateds = [relateds] unless _.isArray(relateds)
    collection = @_ensureCollection(model)
    relateds = ((if related_model = collection.get(Utils.dataId(item)) then Utils.updateModel(related_model, item) else Utils.updateOrNew(item, @reverse_model_type)) for item in relateds)
    related_ids = (Utils.dataId(related) for related in relateds)
    collection.add(relateds)
    if model.isLoaded(@key) # check for needing load
      (model.setLoaded(@key, false); break) for related in relateds when not related.isLoaded()

    # patch in store
    if @join_table
      queue = new Queue(1)

      for related_id in related_ids
        do (related_id) => queue.defer (callback) =>
          return callback(new Error "Many.patchAdd: cannot add an new model. Please save first.") unless related_id

          add = (callback) =>
            attributes = {}
            attributes[@foreign_key] = model.id
            attributes[@reverse_relation.foreign_key] = related_id
            # console.log "Creating join for: #{@model_type.model_name} join: #{Utils.inspect(attributes)}"
            join = new @join_table(attributes)
            join.save callback

          # just create another entry
          return add(callback) if @reverse_relation.type is 'hasMany'

          # check for changes
          (query = {})[@reverse_relation.foreign_key] = related_id
          return @join_table.find query, (err, join_table_json) =>
            return callback(err) if err
            return add(callback) unless join_table_json # create a new join table entry
            return callback() if join_table_json[@foreign_key] is model.id # already related

            # update existing relationship
            join_table_json[@foreign_key] = model.id
            Utils.modelJSONSave(join_table_json, @join_table, callback)

      queue.await callback

    else
      query = {id: $in: related_ids}
      @reverse_model_type.cursor(query).toJSON (err, related_jsons) =>
        queue = new Queue(1)
        for related_json in related_jsons
          do (related_json) => queue.defer (callback) =>
            related_json[@reverse_relation.foreign_key] = model.id
            Utils.modelJSONSave(related_json, @reverse_model_type, callback)
        queue.await callback

  patchRemove: (model, relateds, callback) ->
    return callback(new Error "Many.patchRemove: model has null id for: #{@key}") unless model.id

    # REMOVE ALL
    if arguments.length is 2
      callback = relateds

      return callback() if not @reverse_relation
      if Utils.isModel(model)
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
      if @join_table
        (query = {})[@join_key] = model.id
        return @join_table.destroy(query, callback)

      # clear back links on models and save
      else
        (query = {})[@reverse_relation.foreign_key] = model.id
        @reverse_model_type.cursor(query).toJSON (err, json) =>
          return callback(err) if err

          # clear reverses
          queue = new Queue(1)
          for related_json in json
            do (related_json) => queue.defer (callback) =>
              related_json[@reverse_relation.foreign_key] = null
              Utils.modelJSONSave(related_json, @reverse_model_type, callback)
          queue.await callback
      return

    # REMOVE SOME
    return callback(new Error('Many.patchRemove: embedded relationships are not supported')) if @isEmbedded()
    return callback(new Error('One.patchRemove: missing model for remove')) unless relateds
    relateds = [relateds] unless _.isArray(relateds)
    collection = @_ensureCollection(model)

    # destroy in memory
    for related in relateds
      for current_related_model in collection.models
        (collection.remove(current_related_model); break) if Utils.dataIsSameModel(current_related_model, related) # a match

    related_ids = (Utils.dataId(related) for related in relateds)

    # clear in store through join table
    if @join_table # can directly destroy the join table entry
      query = {}
      query[@join_key] = model.id
      query[@reverse_relation.join_key] = {$in: related_ids}
      @join_table.destroy query, callback

    # clear back links on models and save
    else
      query = {}
      query[@reverse_relation.foreign_key] = model.id
      query.id = {$in: related_ids}
      @reverse_model_type.cursor(query).toJSON (err, json) =>
        return callback(err) if err

        # clear reverses
        queue = new Queue(1)
        for related_json in json
          do (related_json) => queue.defer (callback) =>
            related_json[@reverse_relation.foreign_key] = null
            Utils.modelJSONSave(related_json, @reverse_model_type, callback)
        queue.await callback

  cursor: (model, key, query) ->
    json = if Utils.isModel(model) then model.attributes else model
    (query = _.clone(query or {}))[if @join_table then @join_key else @reverse_relation.foreign_key] = json[@model_type::idAttribute]
    (query.$values or= []).push('id') if key is @virtual_id_accessor
    return @reverse_model_type.cursor(query)

  ####################################
  # Internal
  ####################################
  _bindBacklinks: (model) ->
    return collection if (collection = model.attributes[@key]) instanceof @collection_type
    collection = model.attributes[@key] = new @collection_type()
    return collection unless @reverse_relation # no back links

    events = Utils.set(collection, 'events', {})
    events.add = (related_model) =>
      if @reverse_relation.add
        @reverse_relation.add(related_model, model)
      else
        current_model = related_model.get(@reverse_relation.key)
        is_current = model.id and (Utils.dataId(current_model) is model.id)
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

    collection.on(method, events[method]) for method in ['add', 'remove', 'reset'] # bind

    return collection

  _unbindBacklinks: (model) ->
    return unless events = Utils.get(model, 'events') # already unbound
    Utils.unset(model, 'events')

    collection = model.attributes[@key]
    collection.models.splice()
    events = _.clone()
    for method in ['add', 'remove', 'reset'] # unbind
      collection.off(method, events[method])
      events[method] = null
    return

  _ensureCollection: (model) -> return @_bindBacklinks(model)
  _hasChanged: (model) ->
    return !!Utils.orSet(model, 'rel_dirty', {})[@key] or model.hasChanged(@key)
    return false unless @reverse_relation
    collection = @_ensureCollection(model)
    return true for model in model.models when model.hasChanged(@reverse_relation.foreign_key)
    return false
