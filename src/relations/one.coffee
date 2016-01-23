###
  backbone-orm.js 0.7.14
  Copyright (c) 2013-2016 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

_ = require 'underscore'
Backbone = require 'backbone'

BackboneORM = require '../core'
Queue = require '../lib/queue'
Utils = require '../lib/utils'

# @nodoc
module.exports = class One extends (require './relation')
  constructor: (@model_type, @key, options) ->
    @[key] = value for key, value of options
    @virtual_id_accessor or= BackboneORM.naming_conventions.foreignKey(@key)
    @join_key = @foreign_key or BackboneORM.naming_conventions.foreignKey(@model_type.model_name) unless @join_key
    @foreign_key = BackboneORM.naming_conventions.foreignKey(if @type is 'belongsTo' then @key else (@as or @model_type.model_name)) unless @foreign_key

  initialize: ->
    @reverse_relation = @_findOrGenerateReverseRelation(@)
    throw new Error "Both relationship directions cannot embed (#{@model_type.model_name} and #{@reverse_model_type.model_name}). Choose one or the other." if @embed and @reverse_relation and @reverse_relation.embed
    @model_type.schema().type('id', @reverse_model_type.schema().type('id')) if @embed # inherit id type
    @reverse_model_type?.schema().type(@foreign_key, @model_type?.schema()?.type('id') or @model_type)
    # @model_type?.schema().type(@join_key, @reverse_model_type?.schema()?.type('id') or @reverse_model_type)

  initializeModel: (model) ->
    model.setLoaded(@key, @isEmbedded()) unless model.isLoadedExists(@key) # it may have been set before initialize is called
    @_bindBacklinks(model)

  releaseModel: (model) ->
    @_unbindBacklinks(model)
    delete model._orm

  set: (model, key, value, options) ->
    throw new Error "One.set: Unexpected key #{key}. Expecting: #{@key} or #{@virtual_id_accessor} or #{@foreign_key}" unless ((key is @key) or (key is @virtual_id_accessor) or (key is @foreign_key))
    throw new Error "One.set: cannot set an array for attribute #{@key} on #{@model_type.model_name}" if _.isArray(value)
    value = null if _.isUndefined(value) # Backbone clear or reset

    return @ if value is (previous_related_model = model.get(@key)) # no change
    is_model = Utils.isModel(value)
    new_related_id = Utils.dataId(value)
    previous_related_id = Utils.dataId(previous_related_model)
    Utils.orSet(model, 'rel_dirty', {})[@key] = true

    # update loaded state
    if (previous_related_id isnt new_related_id) or not model.isLoaded(@key)
      if (is_model and (value.isLoaded())) and (new_related_id isnt value)
        model.setLoaded(@key, true)
      else
        model.setLoaded(@key, _.isNull(value))

    # set the relation now or later merge into the existing model
    if value and not is_model
      value = Utils.updateOrNew(value, @reverse_model_type) unless merge_into_existing = (previous_related_id is new_related_id)
    Backbone.Model::set.call(model, @key, value, options) unless merge_into_existing

    # not setting a new model, update the previous model
    if merge_into_existing
      Utils.updateModel(previous_related_model, value)

    # update in memory - clear the reverse relation if it's loaded
    else if (value is null) and @reverse_relation and (@reverse_relation.type is 'hasOne' or @reverse_relation.type is 'belongsTo')
      unless (@embed or @reverse_relation.embed)
        previous_related_model.set(@reverse_relation.key, null) if model.isLoaded(@key) and previous_related_model and (previous_related_model.get(@reverse_relation.key) is model)

    return @

  get: (model, key, callback) ->
    throw new Error "One.get: Unexpected key #{key}. Expecting: #{@key} or #{@virtual_id_accessor} or #{@foreign_key}" unless ((key is @key) or (key is @virtual_id_accessor) or (key is @foreign_key))

    returnValue = =>
      return null unless related_model = model.attributes[@key]
      return if key is @virtual_id_accessor then related_model.id else related_model

    # asynchronous path, needs load
    if callback and not @isVirtual() and not @manual_fetch and not (is_loaded = model.isLoaded(@key)) # already loaded
      @cursor(model, key).toJSON (err, json) =>
        return callback(err) if err
        model.setLoaded(@key, true) if key isnt @virtual_id_accessor

        # already set, merge
        previous_related_model = model.get(@key)
        if previous_related_model and (previous_related_model.id is json?.id)
          Utils.updateModel(previous_related_model, json)
        else
          related_model = if json then Utils.updateOrNew(json, @reverse_model_type) else null
          model.set(@key, related_model)
        callback(null, returnValue())

    # synchronous path
    result = returnValue()
    callback(null, result) if callback and (is_loaded or @manual_fetch)
    return result

  save: (model, callback) ->
    return callback() if not @_hasChanged(model)
    delete Utils.orSet(model, 'rel_dirty', {})[@key]
    return callback() unless related_model = model.attributes[@key]
    @_saveRelated(model, [related_model], callback)

  patchAdd: (model, related, callback) ->
    return callback(new Error "One.patchAdd: model has null id for: #{@key}") unless model.id
    return callback(new Error "One.patchAdd: missing model for: #{@key}") unless related
    return callback(new Error "One.patchAdd: should be provided with one model only for key: #{@key}") if _.isArray(related)
    return callback(new Error "One.patchAdd: cannot add a new model. Please save first.") unless related_id = Utils.dataId(related)

    # look up in the cache
    if @reverse_model_type.cache and not Utils.isModel(related)
      if found_related = @reverse_model_type.cache.get(related_id)
        Utils.updateModel(found_related, related)
        related = found_related
    model.set(@key, related) # set the model

    # belongs to, update the model
    if @type is 'belongsTo'
      # need to fetch or cases where just setting the id could delete data and _rev could be out of date - TODO: write an incremental insert
      @model_type.cursor({id: model.id, $one: true}).toJSON (err, model_json) =>
        return callback(err) if err
        return callback(new Error "Failed to fetch model with id: #{model.id}") unless model_json
        model_json[@foreign_key] = related_id
        model.save model_json, callback

    # not belongs to, update the related
    else
      @cursor(model, @key).toJSON (err, current_related_json) =>
        return callback(err) if err
        return callback() if current_related_json and (related_id is current_related_json[@reverse_model_type::idAttribute]) # already set

        queue = new Queue(1)

        # clear previous
        if current_related_json
          queue.defer (callback) => @patchRemove(model, current_related_json, callback)

        # set new
        queue.defer (callback) =>
          if Utils.isModel(related)
            related_json = related.toJSON() if related.isLoaded()
          else if related_id isnt related
            related_json = related

          # fetch not needed
          if related_json
            related_json[@reverse_relation.foreign_key] = model.id
            Utils.modelJSONSave(related_json, @reverse_model_type, callback)

          # fetch then save
          else
            query = {$one: true}
            query.id = related_id
            @reverse_model_type.cursor(query).toJSON (err, related_json) =>
              return callback(err) if err
              return callback() unless related_json

              related_json[@reverse_relation.foreign_key] = model.id
              Utils.modelJSONSave(related_json, @reverse_model_type, callback)

        queue.await callback

  patchRemove: (model, relateds, callback) ->
    [relateds, callback] = [null, relateds] if arguments.length is 2
    return callback(new Error "One.patchRemove: model has null id for: #{@key}") unless model.id

    # REMOVE ALL
    if arguments.length is 2
      return callback() if not @reverse_relation

      # get memory instance
      if Utils.isModel(model)
        delete Utils.orSet(model, 'rel_dirty', {})[@key]
        related_model = model.get(@key)
        model.set(@key, null)
      else
        related_model = new @reverse_model_type(json) if json = model[@key]

      # clear in memory
      if related_model
        related_model.set(@foreign_key, null) if related_model.get(@foreign_key)?.id is model.id
        cache.set(related_model.id, related_model) if cache = related_model.cache()

      return callback() if @embed # embedded so done

      # clear my links to models and save
      if @type is 'belongsTo'
        @model_type.cursor({id: model.id, $one: true}).toJSON (err, model_json) =>
          return callback(err) if err
          return callback() unless model_json

          model_json[@foreign_key] = null
          Utils.modelJSONSave(model_json, @model_type, callback)

      # clear back links on models and save
      else
        @cursor(model, @key).toJSON (err, related_json) =>
          return callback(err) if err
          return callback() unless related_json
          return callback() unless related_json[@reverse_relation.foreign_key] is model.id

          related_json[@reverse_relation.foreign_key] = null
          Utils.modelJSONSave(related_json, @reverse_model_type, callback)
      return

    # REMOVE SOME
    return callback(new Error('One.patchRemove: missing model for remove')) unless relateds
    relateds = [relateds] unless _.isArray(relateds)

    # clear in memory
    if related_model = model.get(@key)
      (model.set(@key, null); break) for related in relateds when Utils.dataIsSameModel(related_model, related)
    related_ids = (Utils.dataId(related) for related in relateds)

    return callback() if @embed # embedded so done

    # clear my links to models and save
    if @type is 'belongsTo'
      @model_type.cursor({id: model.id, $one: true}).toJSON (err, model_json) =>
        return callback(err) if err
        return callback() unless model_json
        return callback() unless _.contains(related_ids, model_json[@foreign_key])

        model_json[@foreign_key] = null
        Utils.modelJSONSave(model_json, @model_type, callback)

    # clear back links on models and save
    else
      @cursor(model, @key).toJSON (err, related_json) =>
        return callback(err) if err
        return callback() unless related_json
        return callback() unless _.contains(related_ids, related_json[@reverse_model_type::idAttribute])

        related_json[@reverse_relation.foreign_key] = null
        Utils.modelJSONSave(related_json, @reverse_model_type, callback)

  appendJSON: (json, model) ->
    return if @isVirtual() # skip virtual attributes

    json_key = if @embed then @key else @foreign_key
    unless related_model = model.attributes[@key]
      json[json_key] = null if @embed or @type is 'belongsTo'
      return
    return json[json_key] = related_model.toJSON() if @embed
    return json[json_key] = related_model.id if @type is 'belongsTo'

  cursor: (model, key, query) ->
    query = _.extend({$one:true}, query or {})
    if Utils.isModel(model)
      if @type is 'belongsTo'
        (query.$zero = true; delete query.id) unless query.id = model.attributes[@key]?.id
      else
        throw new Error 'Cannot create cursor for non-loaded model' unless model.id
        query[@reverse_relation.foreign_key] = model.id
    else
      # json
      if @type is 'belongsTo'
        (query.$zero = true; delete query.id) unless query.id = model[@foreign_key]
      else
        throw new Error 'Cannot create cursor for non-loaded model' unless model.id
        query[@reverse_relation.foreign_key] = model.id

    query.$values = ['id'] if key is @virtual_id_accessor
    return @reverse_model_type.cursor(query)

  ####################################
  # Internal
  ####################################
  _bindBacklinks: (model) ->
    return unless @reverse_relation
    events = Utils.set(model, 'events', {})

    setBacklink = (related_model) =>
      if @reverse_relation.add
        @reverse_relation.add(related_model, model)
      else
        related_model.set(@reverse_relation.key, model)

    events.change = (model) =>
      related_model = model.get(@key)
      previous_related_model = model.previous(@key)
      return if Utils.dataId(related_model) is Utils.dataId(previous_related_model) # no change
      Utils.orSet(model, 'rel_dirty', {})[@key] = true

      # update backlinks
      if previous_related_model and (@reverse_relation and @reverse_relation.type isnt 'belongsTo') # allow for multiple
        if @reverse_relation.remove
          @reverse_relation.remove(previous_related_model, model) if not @isVirtual() or not related_model
        else
          current_model = previous_related_model.get(@reverse_relation.key)
          previous_related_model.set(@reverse_relation.key, null) if Utils.dataId(current_model) is model.id

      setBacklink(related_model) if related_model

    # TODO: how to unbind
    model.on("change:#{@key}", events.change) # bind

    # already set, set up initial value
    if related_model = model.get(@key)
      setBacklink(related_model)
    else
      model.attributes[@key] = null

    return model

  _unbindBacklinks: (model) ->
    return unless events = Utils.get(model, 'events') # already unbound
    Utils.unset(model, 'events')

    model.attributes[@key] = null
    model.off("change:#{@key}", events.change) # unbind
    events.change = null
    return

  _hasChanged: (model) -> return !!Utils.orSet(model, 'rel_dirty', {})[@key] or model.hasChanged(@key)
