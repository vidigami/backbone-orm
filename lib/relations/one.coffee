util = require 'util'
_ = require 'underscore'
Backbone = require 'backbone'
inflection = require 'inflection'

Utils = require '../utils'
adapters = Utils.adapters

module.exports = class One
  constructor: (@model_type, @key, options) ->
    @[key] = value for key, value of options
    @ids_accessor = "#{@key}_id"
    @foreign_key = inflection.foreign_key(if @type is 'belongsTo' then @key else @model_type.model_name) unless @foreign_key

  initialize: ->
    @reverse_relation = Utils.reverseRelation(@reverse_model_type, @model_type.model_name) if @model_type.model_name
    throw new Error "Both relationship directions cannot embed (#{@model_type.model_name} and #{@reverse_model_type.model_name}). Choose one or the other." if @embed and @reverse_relation and @reverse_relation.embed

    # check for reverse since they need to store the foreign key
    if not @reverse_relation and @type is 'hasOne'
      unless _.isFunction(@reverse_model_type.schema) # not a relational model
        @reverse_model_type.sync = @model_type.createSync(@reverse_model_type, !!@model_type.cache())
      reverse_schema = @reverse_model_type.schema()
      reverse_key = inflection.underscore(@model_type.model_name)
      reverse_schema.addRelation(@reverse_relation = new One(@reverse_model_type, reverse_key, {type: 'belongsTo', reverse_model_type: @model_type}))

  initializeModel: (model, key) ->

  set: (model, key, value, options) ->
    throw new Error "One::set: Unexpected key #{key}. Expecting: #{@key} or #{@ids_accessor}" unless (key is @key or key is @ids_accessor)
    value = null if _.isUndefined(value) # Backbone clear or reset

    if @type is 'belongsTo' and key is @foreign_key
      model._orm_lookups or= {}
      model._orm_lookups[@foreign_key] = value
      return @
    return @ if @has(model, @key, value) # already set

    previous_related_model = model.attributes[@key]
    related_model = if value then Utils.createRelated(@reverse_model_type, value) else null
    Backbone.Model::set.call(model, @key, related_model, options)

    # update backlinks
    if @reverse_relation and previous_related_model
      if @reverse_relation.remove then @reverse_relation.remove(previous_related_model, model) else previous_related_model.set(@reverse_relation.key, null)

    # update backlinks
    if @reverse_relation and related_model
      if @reverse_relation.add then @reverse_relation.add(related_model, model) else related_model.set(@reverse_relation.key, model)

    return @

  get: (model, key, callback) ->
    throw new Error "One::get: Unexpected key #{key}. Expecting: #{@key} or #{@ids_accessor}" unless (key is @key or key is @ids_accessor)

    returnValue = =>
      return null unless related_model = model.attributes[@key]
      return if key is @ids_accessor then related_model.get('id') else related_model

    # asynchronous path, needs load
    is_loaded = @_fetchRelated model, key, (err) =>
      return (if callback then callback(err) else console.error "One: unhandled error: #{err}. Please supply a callback") if err
      callback(null, returnValue()) if callback

    # synchronous path
    result = returnValue()
    callback(null, result) if is_loaded and callback
    return result

  save: (model, key, callback) ->
    return callback() if not @reverse_relation or not (related_model = model.attributes[@key])

    if @reverse_relation.type is 'hasOne'
      # TODO: optimize correct ordering (eg. save other before us in save method)
      unless related_model.get('id')
        return related_model.save {}, adapters.bbCallback (err) =>
          return callback() if err
          model.save {}, adapters.bbCallback callback

      return callback()

    else if @reverse_relation.type is 'belongsTo'
      return related_model.save {}, adapters.bbCallback callback if related_model.hasChanged(@reverse_relation.key) or not related_model.get('id')

    else # hasMany
      # nothing to do?

    callback() # nothing to save

  appendJSON: (json, model, key) ->
    return if key is @ids_accessor # only write the relationships

    json_key = if @embed then key else @ids_accessor
    return json[json_key] = null unless related_model = model.attributes[key]
    return json[json_key] = related_model.toJSON() if @embed
    return json[json_key] = related_model.get('id') if @type is 'belongsTo'

  has: (model, key, item) ->
    current_related_model = model.attributes[@key]
    return !item if not current_related_model

    # compare ids
    current_id = current_related_model.get('id')
    return current_id is item.get('id') if item instanceof Backbone.Model
    return current_id is item.id if _.isObject(item)
    return current_id is item

  # TODO: check which objects are already loaded in cache and ignore ids
  batchLoadRelated: (models_json, callback) ->
    query = {}
    if @type is 'belongsTo'
      query.id = {$in: (json[@foreign_key] for json in models_json)}
    else
      query[@foreign_key] = {$in: (json.id for json in models_json)}
    @reverse_model_type.cursor(query).toJSON callback

  # TODO: optimize so don't need to check each time
  _isLoaded: (model, key) ->
    related_model = model.attributes[@key]
    return related_model and not related_model._orm_needs_load

  # TODO: check which objects are already loaded in cache and ignore ids
  _fetchPlaceholder: (model, key, callback) ->
    related_model = model.attributes[@key]
    return callback(null, related_model) if related_model

    if @type is 'belongsTo'
      if model._orm_lookups and (related_id = model._orm_lookups[@foreign_key])
        model.set(@key, related_model = Utils.createRelated(@reverse_model_type, related_id))
        return callback(null, related_model)
      return callback(null, null)
    else
      query = {$one:true}
      query[@foreign_key] = model.attributes.id
      @reverse_model_type.cursor(query).toJSON (err, json) =>
        return callback(err) if err
        model.set(@key, related_model = if json then Utils.createRelated(@reverse_model_type, json) else null)
        callback(null, related_model)

  # TODO: optimize so don't need to check each time
  _fetchRelated: (model, key, callback) ->
    return true if @_isLoaded(model, key) # already loaded

    # load placeholders with ids
    @_fetchPlaceholder model, key, (err, related_model) =>
      return callback(err) if err
      return callback(null, null) unless related_model # no relation
      return callback(null, related_model) if key is @ids_accessor # ids only, no need to fetch the models
      return callback(null, related_model) unless related_model._orm_needs_load # already loaded
      return callback(new Error "Missing id for load: #{util.inspect(related_model.attributes)}") unless id = related_model.get('id')

      # load actual model
      @reverse_model_type.cursor(id).toJSON (err, model_json) =>
        return callback(err) if err
        return callback(new Error "Model not found. Id #{id}") if not model_json

        # update
        delete related_model._orm_needs_load
        related_model.set(key, model_json)
        cache.updateCached(related_model) if cache = @reverse_model_type.cache()
        callback(null, related_model)

    return false
