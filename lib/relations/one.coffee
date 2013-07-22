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
    if @as
      @reverse_relation = @reverse_model_type.relation(@as)
    else
      @reverse_relation = Utils.reverseRelation(@reverse_model_type, @model_type.model_name) if @model_type.model_name

    throw new Error "Both relationship directions cannot embed (#{@model_type.model_name} and #{@reverse_model_type.model_name}). Choose one or the other." if @embed and @reverse_relation and @reverse_relation.embed

    # check for reverse since they need to store the foreign key
    if not @reverse_relation and @type is 'hasOne'
      unless _.isFunction(@reverse_model_type.schema) # not a relational model
        @reverse_model_type.sync = @model_type.createSync(@reverse_model_type, !!@model_type.cache())
      reverse_schema = @reverse_model_type.schema()
      reverse_key = inflection.underscore(@model_type.model_name)
      reverse_schema.addRelation(@reverse_relation = new One(@reverse_model_type, reverse_key, {type: 'belongsTo', reverse_model_type: @model_type, manual_fetch: true}))

  initializeModel: (model, key) -> @_bindBacklinks(model)

  set: (model, key, value, options) ->
    throw new Error "One::set: Unexpected key #{key}. Expecting: #{@key} or #{@ids_accessor}" unless (key is @key or key is @ids_accessor)
    throw new Error "One::set: cannot set an array for attribute #{@key} on #{@model_type.model_name}" if _.isArray(value)
    value = null if _.isUndefined(value) # Backbone clear or reset

    related_model = model.attributes[@key]
    if @has(model, @key, value)
      return @ unless related_model # null

      if value instanceof Backbone.Model
        if (related_model isnt value) and not value._orm_needs_load
          related_model.set(value.toJSON())
          delete related_model._orm_needs_load

      else if _.isObject(value)
        related_model.set(value)
        delete related_model._orm_needs_load

      cache.update(@model_type.model_name, related_model) if related_model.get('id') and (cache = @model_type.cache()) and not related_model._orm_needs_load
      return @

    related_model = if value then @reverse_model_type.findOrNew(value) else null
    Backbone.Model::set.call(model, @key, related_model, options)
    return @

  get: (model, key, callback) ->
    throw new Error "One::get: Unexpected key #{key}. Expecting: #{@key} or #{@ids_accessor}" unless (key is @key or key is @ids_accessor)

    returnValue = =>
      return null unless related_model = model.attributes[@key]
      return if key is @ids_accessor then related_model.get('id') else related_model

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
    return callback() if not @reverse_relation or not (related_model = model.attributes[@key])

    if @reverse_relation.type is 'hasOne'
      # TODO: optimize correct ordering (eg. save other before us in save method)
      unless related_model.get('id')
        return related_model.save {}, Utils.bbCallback (err) =>
          return callback() if err
          model.save {}, Utils.bbCallback callback

      return callback()

    else if @reverse_relation.type is 'belongsTo'
      return related_model.save {}, Utils.bbCallback callback if related_model.hasChanged(@reverse_relation.key) or not related_model.get('id')

    else # hasMany
      # nothing to do?

    callback() # nothing to save

  appendJSON: (json, model, key) ->
    return if key is @ids_accessor # only write the relationships

    json_key = if @embed then key else @ids_accessor
    return json[json_key] = null unless related_model = model.attributes[key]
    return json[json_key] = related_model.toJSON() if @embed
    return json[json_key] = related_model.get('id') if @type is 'belongsTo'

  has: (model, key, data) ->
    return data is current_related_model if not current_related_model = model.attributes[@key]
    return current_related_model.get('id') is Utils.dataId(data)

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
    return !!(related_model and not related_model._orm_needs_load)

  # TODO: optimize so don't need to check each time
  # TODO: check which objects are already loaded in cache and ignore ids
  _fetchRelated: (model, key, callback) ->
    return true if @_isLoaded(model, key) # already loaded

    # nothing to load
    return true unless model.attributes.id

    # not loaded but we have the id, create a model
    if @type is 'belongsTo'
      return true if not model.attributes[@key]

    # Will only load ids if key is @ids_accessor
    @cursor(model, key).toJSON (err, json) =>
      return callback(err) if err
      model.set(@key, related_model = if json then @reverse_model_type.findOrNew(json) else null)
      if related_model
        delete related_model._orm_needs_load
        cache.update(@reverse_model_type.model_name, related_model) if cache = @reverse_model_type.cache()
      callback(null, related_model)

    return false

  _bindBacklinks: (model) ->
    return unless @reverse_relation

    model._orm_bindings = {}
    model._orm_bindings.change = (model) =>
      # update backlinks
      if previous_related_model = model.previous(@key)
        if @reverse_relation.remove then @reverse_relation.remove(previous_related_model, model) else previous_related_model.set(@reverse_relation.key, null)

      # update backlinks
      if related_model = model.get(@key)
        if @reverse_relation.add then @reverse_relation.add(related_model, model) else related_model.set(@reverse_relation.key, model)

    model.on("change:#{@key}", model._orm_bindings.change)
    return model

  cursor: (model, key, query) ->
    return @reverse_model_type.cursor(@query(model, key, query))

  query: (model, key, _query) ->
    query = _.extend(_query or {}, {$one:true})
    if model instanceof Backbone.Model
      if @type is 'belongsTo'
        if related_model = related_model = model.attributes[@key]
          query.id = related_model.get('id')
      else
        query[@foreign_key] = model.attributes.id
    else
      # json
      if @type is 'belongsTo'
        query.id = model[@foreign_key]
      else
        query[@foreign_key] = model.id

    query.$values = ['id'] if key is @ids_accessor
    return query
