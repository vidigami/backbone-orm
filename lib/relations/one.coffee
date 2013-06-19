util = require 'util'
_ = require 'underscore'
Backbone = require 'backbone'
inflection = require 'inflection'

Utils = require '../../utils'

module.exports = class One
  constructor: (@model_type, @key, options) ->
    @[key] = value for key, value of options
    @ids_accessor = "#{@key}_id"
    @foreign_key = inflection.foreign_key(if @type is 'belongsTo' then @key else @model_type.model_name) unless @foreign_key

  initialize: ->
    @reverse_relation = Utils.reverseRelation(@reverse_model_type, @model_type.model_name) if @model_type.model_name
    throw new Error "Both relationship directions cannot embed (#{@model_type.model_name} and #{@reverse_model_type.model_name}). Choose one or the other." if @embed and @reverse_relation and @reverse_relation.embed

  set: (model, key, value, options) ->
    throw new Error "One::set: Unexpected key #{key}. Expecting: #{@key} or #{@ids_accessor}" unless (key is @key or key is @ids_accessor)
    return @ if @has(model, @key, value) # already set

    # clear reverse
    if @reverse_relation
      if @has(model, @key, value) and (related_model = model.attributes[@key])
        if @reverse_relation.remove
          @reverse_relation.remove(related_model, model)
        else
          related_model.set(@reverse_relation.key, null)

    related_model = if value then Utils.createRelated(@reverse_model_type, value) else null

    # TODO: Allow sql to sync...make a notification? use Backbone.Events?
    # _set.call(model, @foreign_key, related_model.attributes.id, options) if @type is 'belongsTo'
    # _set.call(related_model, @foreign_key, model.attributes.id, options) if @type is 'hasOne'

    Backbone.Model::set.call(model, @key, related_model, options)
    return @ if not related_model or not @reverse_relation

    if @reverse_relation.add
      @reverse_relation.add(related_model, model)
    else
      related_model.set(@reverse_relation.key, model)

    return @

  get: (model, key, callback) ->
    throw new Error "One::get: Unexpected key #{key}. Expecting: #{@key} or #{@ids_accessor}" unless (key is @key or key is @ids_accessor)
    returnValue = (related_model) =>
      return null unless related_model = model.attributes[@key]
      return if key is @ids_accessor then related_model.get('id') else related_model

    # asynchronous path, needs load
    is_loaded = @_fetchRelated model, key, (err, related_model) =>
      return if callback then callback(err) console.log "One: unhandled error: #{err}. Please supply a callback" if err
      callback(null, returnValue()) if callback

    # synchronous path
    result = returnValue()
    callback(null, result) if is_loaded and callback
    return result

  appendJSON: (json, model, key) ->
    return if key is @ids_accessor # only write the relationships

    json_key = if @embed then key else @ids_accessor
    return json[json_key] = null unless related_model = model.attributes[key]
    return json[json_key] = if @embed then related_model.toJSON() else related_model.get('id')

  has: (model, key, item) ->
    current_related_model = model.attributes[@key]
    return false if (current_related_model and not item) or (not current_related_model and item)

    # compare ids
    current_id = current_related_model.get('id')
    return current_id is item.get('id') if item instanceof Backbone.Model
    return current_id is item.id if _.isObject(item)
    return current_id is item

  # TODO: optimize so don't need to check each time
  _isLoaded: (model, key) ->
    related_model = model.attributes[@key]
    return related_model and not related_model._orm_needs_load

  _fetchPlaceholder: (model, key, callback) -> callback(null, model.attributes[@key])

  # TODO: optimize so don't need to check each time
  _fetchRelated: (model, key, callback) ->
    return true if @_isLoaded(model, key) # already loaded

    # load placeholders with ids
    @_fetchPlaceholder model, key, (err, related_model) =>
      return callback(err) if err
      return callback(null, null) unless related_model # no relation
      return callback(null, related_model) unless related_model._orm_needs_load # already loaded
      return callback(new Error "Missing id for load") unless id = related_model.get('id')

      # load actual model
      @reverse_model_type.cursor(id).toJSON (err, model_json) =>
        return callback(err) if err
        return callback(new Error "Model not found. Id #{id}") if not model_json

        # update
        delete related_model._orm_needs_load
        related_model.set(key, model_json)
        @reverse_model_type._cache.markLoaded(related_model) if @reverse_model_type._cache
        callback(null, related_model)

    return false
