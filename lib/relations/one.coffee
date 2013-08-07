util = require 'util'
_ = require 'underscore'
Backbone = require 'backbone'
inflection = require 'inflection'

Utils = require '../utils'

# @private
module.exports = class One
  constructor: (@model_type, @key, options) ->
    @[key] = value for key, value of options
    @ids_accessor or= "#{@key}_id"
    @foreign_key = inflection.foreign_key(if @type is 'belongsTo' then @key else (@as or @model_type.model_name)) unless @foreign_key

  initialize: ->
    @reverse_relation = Utils.findOrGenerateReverseRelation(@)
    throw new Error "Both relationship directions cannot embed (#{@model_type.model_name} and #{@reverse_model_type.model_name}). Choose one or the other." if @embed and @reverse_relation and @reverse_relation.embed

  initializeModel: (model, key) ->
    model.setLoaded(@key, !!(@embed or @reverse_relation?.embed))
    @_bindBacklinks(model)

  set: (model, key, value, options) ->
    throw new Error "One::set: Unexpected key #{key}. Expecting: #{@key} or #{@ids_accessor}" unless (key is @key or key is @ids_accessor)
    throw new Error "One::set: cannot set an array for attribute #{@key} on #{@model_type.model_name}" if _.isArray(value)
    value = null if _.isUndefined(value) # Backbone clear or reset

    return @ if value is (previous_related_model = model.get(@key)) # no change
    value_is_model = (value instanceof Backbone.Model)
    model.setLoaded(@key, true) if not model.isLoaded(@key) and (value_is_model or _.isObject(value)) # set loaded state

    # set the relation now or later merge into the existing model
    if value and not value_is_model
      value = Utils.updateOrNew(value, @reverse_model_type) unless merge_into_existing = !!previous_related_model
    Backbone.Model::set.call(model, @key, value, options) unless merge_into_existing

    # not setting a new model, update the previous model
    if merge_into_existing
      Utils.updateModel(previous_related_model, value)

    # clear the reverse relation if it's loaded
    else if (value is null) and @reverse_relation and (@reverse_relation.type is 'hasOne' or @reverse_relation.type is 'belongsTo')
      unless @embed or @reverse_relation.embed
        if model.isLoaded(@key)
          previous_related_model.set(@reverse_relation.key, null) if previous_related_model and previous_related_model.get(@reverse_relation.key)
          # Note the model as it needs to be saved to have its foreign key updated
        @_queueDependentSave(model) if @type is 'hasOne'

    return @

  get: (model, key, callback) ->
    throw new Error "One::get: Unexpected key #{key}. Expecting: #{@key} or #{@ids_accessor}" unless (key is @key or key is @ids_accessor)

    returnValue = =>
      return null unless related_model = model.attributes[@key]
      return if key is @ids_accessor then related_model.id else related_model

    # asynchronous path, needs load
    if not @manual_fetch and callback
      is_loaded = @_fetchRelated model, key, (err) =>
        return callback(err) if err
        callback(null, returnValue())

    # synchronous path
    result = returnValue()
    callback(null, result) if (is_loaded or @manual_fetch) and callback
    return result

  save: (model, key, callback) ->
    return callback() if not @reverse_relation
    related_model = model.attributes[@key]

    if @reverse_relation.type is 'hasOne'
      # TODO: optimize correct ordering (eg. save other before us in save method)
      if related_model and not related_model.id
        return related_model.save {}, Utils.bbCallback (err) =>
          return callback() if err
          model.save {}, Utils.bbCallback callback

      return callback()

    else if @reverse_relation.type is 'belongsTo'
      if related_model and (related_model.hasChanged(@reverse_relation.key) or not related_model.id)
        return related_model.save {}, Utils.bbCallback(callback)

      else if @_hasDependentSave(model)
        return @_clearRelation(model, callback)

    else # hasMany
      # nothing to do?

    callback() # nothing to save

  destroy: (model, callback) ->
    return callback() if not @reverse_relation
    return @_clearRelation(model, callback) if @type is 'hasOne'
    callback() # nothing to save

  appendJSON: (json, model, key) ->
    return if key is @ids_accessor # only write the relationships

    json_key = if @embed then key else @ids_accessor
    return json[json_key] = null unless related_model = model.attributes[key]
    return json[json_key] = related_model.toJSON() if @embed
    return json[json_key] = related_model.id if @type is 'belongsTo'

  cursor: (model, key, query) ->
    query = _.extend({$one:true}, query or {})
    if model instanceof Backbone.Model
      if @type is 'belongsTo'
        if related_model = related_model = model.attributes[@key]
          query.id = related_model.id
      else
        query[@foreign_key] = model.id
    else
      # json
      if @type is 'belongsTo'
        query.id = model[@foreign_key]
      else
        query[@foreign_key] = model.id

    query.$values = ['id'] if key is @ids_accessor
    return @reverse_model_type.cursor(query)

  ####################################
  # Internal
  ####################################
  _queueDependentSave: (model) ->
    model._orm or= {}
    (model._orm.dependent_saves or= {})[@key] = true

  _clearDependentSave: (model) -> delete model._orm?.dependent_saves?[@key]

  _hasDependentSave: (model) -> model._orm?.dependent_saves?[@key]

  # TODO: optimize so don't need to check each time
  # TODO: check which objects are already loaded in cache and ignore ids
  _fetchRelated: (model, key, callback) ->
    return true if model.isLoaded(@key) or not model.id # already loaded or not loadable

    @cursor(model, key).toJSON (err, json) =>
      return callback(err) if err

      model.set(@key, related_model = if json then Utils.updateOrNew(json, @reverse_model_type) else null)
      model.setLoaded(@key, true)
      callback(null, related_model)

    return false

  _clearRelation: (model, callback) ->
    (update = {})[@foreign_key] = null
    @_clearDependentSave(model)
    if related_model = model.attributes[@key]
      related_model.save update, Utils.bbCallback callback
    else
      @cursor(model, @key).toModels (err, related_model) =>
        return callback(err) if err
        return callback() unless related_model
        related_model.save update, Utils.bbCallback callback

  _bindBacklinks: (model) ->
    return unless @reverse_relation

    model._orm_bindings = {}
    model._orm_bindings.change = (model) =>
      related_model = model.get(@key)

      # update backlinks
      if previous_related_model = model.previous(@key)
        if @reverse_relation.remove then @reverse_relation.remove(previous_related_model, model) else previous_related_model.set(@reverse_relation.key, null)
      if related_model
        if @reverse_relation.add then @reverse_relation.add(related_model, model) else related_model.set(@reverse_relation.key, model)

    model.on("change:#{@key}", model._orm_bindings.change)
    return model
