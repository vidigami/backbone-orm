###
  backbone-orm.js 0.7.14
  Copyright (c) 2013-2016 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

Backbone = require 'backbone'
_ = require 'underscore'

BackboneORM = require '../core'
Queue = require '../lib/queue'
Utils = require '../lib/utils'
JSONUtils = require '../lib/json_utils'

# @nodoc
module.exports = class Many extends (require './relation')
  constructor: (@model_type, @key, options) ->
    @[key] = value for key, value of options
    @virtual_id_accessor or= BackboneORM.naming_conventions.foreignKey(@key, true)
    @join_key = @foreign_key or BackboneORM.naming_conventions.foreignKey(@model_type.model_name) unless @join_key
    @foreign_key = BackboneORM.naming_conventions.foreignKey(@as or @model_type.model_name) unless @foreign_key
    @_adding_ids = {}
    unless @collection_type
      reverse_model_type = @reverse_model_type

      # @nodoc
      class Collection extends Backbone.Collection
        model: reverse_model_type
      @collection_type = Collection

  initialize: ->
    @reverse_relation = @_findOrGenerateReverseRelation(@)
    throw new Error "Both relationship directions cannot embed (#{@model_type.model_name} and #{@reverse_model_type.model_name}). Choose one or the other." if @embed and @reverse_relation and @reverse_relation.embed
    throw new Error "The reverse of a hasMany relation should be `belongsTo`, not `hasOne` (#{@model_type.model_name} and #{@reverse_model_type.model_name})." if @reverse_relation?.type is 'hasOne'
    @model_type.schema().type('id', @reverse_model_type.schema().type('id')) if @embed # inherit id type
    @reverse_model_type?.schema().type(@foreign_key, @model_type?.schema()?.type('id') or @model_type)
    # @model_type?.schema().type(@join_key, @reverse_model_type?.schema()?.type('id') or @reverse_model_type)

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
    throw new Error "HasMany.set: Unexpected type to set #{key}. Expecting array: #{JSONUtils.stringify(value)}" unless _.isArray(value)

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
    # Fixes 'Uncaught Maximum call stack size exceeded' in backbone-mongo tests
    if related_model.id
      adding_count = @_adding_ids[related_model.id] = (@_adding_ids[related_model.id] or 0) + 1

    collection = @_ensureCollection(model)
    current_related_model = collection.get(related_model.id)
    return if current_related_model is related_model
    # Utils.orSet(model, 'rel_dirty', {})[@key] = true # TODO: add tests for updating

    # TODO: this is needed for model lifecycle - not knowing when a model is actually disposed and not wanting to remove a model from a relationship
    # throw new Error "\nModel added twice: #{JSONUtils.stringify(current_related_model)}\nand\n#{JSONUtils.stringify(related_model)}" if current_related_model
    collection.remove(current_related_model) if current_related_model
    @reverse_model_type.cache.set(related_model.id, related_model) if @reverse_model_type.cache and related_model.id # make sure the latest model is in the cache

    return_value = collection.add(related_model, silent: adding_count > 1)
    @_adding_ids[related_model.id]-- if related_model.id
    return return_value

  remove: (model, related_model) ->
    collection = @_ensureCollection(model)
    return unless current_related_model = collection.get(related_model.id)
    Utils.orSet(model, 'rel_dirty', {})[@key] = true
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
      Utils.each related_ids, ((related_id, callback) =>
        return callback(new Error "Many.patchAdd: cannot add an new model. Please save first.") unless related_id

        add = (callback) =>
          (attributes = {})[@foreign_key] = model.id
          attributes[@reverse_relation.foreign_key] = related_id
          @join_table.exists attributes, (err, exists) =>
            return callback(err) if err
            return callback(new Error "Join already exists: #{JSON.stringify(attributes)}") if exists
            new @join_table(attributes).save callback

        # just create another entry
        return add(callback) if @reverse_relation.type is 'hasMany'

        # check for changes
        (query = {$one: true})[@reverse_relation.foreign_key] = related_id
        return @join_table.cursor(query).toJSON (err, join_table_json) =>
          return callback(err) if err
          return add(callback) unless join_table_json # create a new join table entry
          return callback() if join_table_json[@foreign_key] is model.id # already related

          # update existing relationship
          join_table_json[@foreign_key] = model.id
          Utils.modelJSONSave(join_table_json, @join_table, callback)
      ), callback

    else
      query = {id: $in: related_ids}
      @reverse_model_type.cursor(query).toJSON (err, related_jsons) =>
        Utils.each related_jsons, ((related_json, callback) =>
          related_json[@reverse_relation.foreign_key] = model.id
          Utils.modelJSONSave(related_json, @reverse_model_type, callback)
        ), callback

  patchRemove: (model, relateds, callback) ->
    [relateds, callback] = [null, relateds] if arguments.length is 2
    return callback(new Error "Many.patchRemove: model has null id for: #{@key}") unless model.id

    # REMOVE ALL
    if arguments.length is 2
      return callback() if not @reverse_relation

      # get memory instance
      if Utils.isModel(model)
        delete Utils.orSet(model, 'rel_dirty', {})[@key]
        collection = @_ensureCollection(model)
        related_models = _.clone(collection.models)
      else
        related_models = (new @reverse_model_type(json) for json in (model[@key] or []))

      # clear in memory
      for related_model in related_models
        related_model.set(@foreign_key, null) if related_model.get(@foreign_key)?.id is model.id
        cache.set(related_model.id, related_model) if cache = related_model.cache() # ensure the cache is up-to-date

      return callback() if @embed # embedded so done

      # clear in store through join table
      if @join_table
        (query = {})[@join_key] = model.id
        return @join_table.destroy(query, callback)

      # clear my links to models and save
      else if @type is 'belongsTo'
        @model_type.cursor({id: model.id, $one: true}).toJSON (err, model_json) =>
          return callback(err) if err
          return callback() unless model_json

          model_json[@foreign_key] = null
          Utils.modelJSONSave(model_json, @model_type, callback)

      # clear back links on models and save
      else
        (query = {})[@reverse_relation.foreign_key] = model.id
        @reverse_model_type.cursor(query).toJSON (err, json) =>
          return callback(err) if err

          # clear reverses
          Utils.each json, ((related_json, callback) =>
            related_json[@reverse_relation.foreign_key] = null
            Utils.modelJSONSave(related_json, @reverse_model_type, callback)
          ), callback
      return

    # REMOVE SOME
    return callback(new Error('Many.patchRemove: missing model for remove')) unless relateds
    relateds = [relateds] unless _.isArray(relateds)
    collection = @_ensureCollection(model)

    # clear in memory
    for related in relateds
      (collection.remove(related_model); break) for related_model in collection.models when Utils.dataIsSameModel(related_model, related)
    related_ids = (Utils.dataId(related) for related in relateds)

    return callback() if @embed # embedded so done

    # clear in store through join table
    if @join_table # can directly destroy the join table entry
      query = {}
      query[@join_key] = model.id
      query[@reverse_relation.join_key] = {$in: related_ids}
      @join_table.destroy query, callback

    # clear my links to models and save
    else if @type is 'belongsTo'
      @model_type.cursor({id: model.id, $one: true}).toJSON (err, model_json) =>
        return callback(err) if err
        return callback() unless model_json
        return callback() unless _.contains(related_ids, model_json[@foreign_key])

        model_json[@foreign_key] = null
        Utils.modelJSONSave(model_json, @model_type, callback)

    # clear back links on models and save
    else
      query = {}
      query[@reverse_relation.foreign_key] = model.id
      query.id = {$in: related_ids}
      @reverse_model_type.cursor(query).toJSON (err, json) =>
        return callback(err) if err

        # clear reverses
        Utils.each json, ((related_json, callback) =>
          return callback() unless related_json[@reverse_relation.foreign_key] is model.id
          related_json[@reverse_relation.foreign_key] = null
          Utils.modelJSONSave(related_json, @reverse_model_type, callback)
        ), callback

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
      # Utils.orSet(model, 'rel_dirty', {})[@key] = true # TODO: add tests for updating
      if @reverse_relation.add
        @reverse_relation.add(related_model, model)
      else
        current_model = related_model.get(@reverse_relation.key)
        is_current = model.id and (Utils.dataId(current_model) is model.id)
        related_model.set(@reverse_relation.key, model) if not is_current or (is_current and not current_model.isLoaded())

    events.remove = (related_model) =>
      Utils.orSet(model, 'rel_dirty', {})[@key] = true
      if @reverse_relation.remove
        @reverse_relation.remove(related_model, model)
      else
        current_model = related_model.get(@reverse_relation.key)
        related_model.set(@reverse_relation.key, null) if Utils.dataId(current_model) is model.id

    events.reset = (collection, options) =>
      Utils.orSet(model, 'rel_dirty', {})[@key] = true
      current_models = collection.models
      previous_models = options.previousModels or []
      changes = _.groupBy(previous_models, (test) -> if !!_.find(current_models, (current_model) -> current_model.id is test.id) then 'kept' else 'removed')
      added = if changes.kept then _.select(current_models, (test) -> !_.find(changes.kept, (keep_model) -> keep_model.id is test.id)) else current_models

      # update back links
      (events.remove(related_model) for related_model in changes.removed) if changes.removed
      (events.add(related_model) for related_model in added)
      return

    collection.on(method, events[method]) for method in ['add', 'remove', 'reset'] # bind

    return collection

  _unbindBacklinks: (model) ->
    return unless events = Utils.get(model, 'events') # already unbound
    Utils.unset(model, 'events')

    collection = model.attributes[@key]
    collection.models.splice()
    for method in ['add', 'remove', 'reset'] # unbind
      collection.off(method, events[method])
      events[method] = null
    return

  _ensureCollection: (model) -> return @_bindBacklinks(model)
  _hasChanged: (model) -> return !!Utils.orSet(model, 'rel_dirty', {})[@key] or model.hasChanged(@key)
