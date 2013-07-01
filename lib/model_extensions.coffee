util = require 'util'
_ = @_ or require 'underscore'
Backbone = @Backbone or require 'backbone'
JSONUtils = require './json_utils'
Queue = require 'queue-async'
Utils = require './utils'

module.exports = (model_type) ->

  ###################################
  # Backbone ORM - Sync Accessors
  ###################################
  model_type.sync = -> model_type._sync
  model_type.createSync = (other_model_type, cache) -> model_type._sync.fn('createSync', other_model_type, cache)

  ###################################
  # Backbone ORM - Class Extensions
  ###################################
  model_type.findOrCreate = (data) ->
    throw 'findOrCreate requires data' unless data
    return data if (data instanceof Backbone.Model) or (data instanceof Backbone.Collection)
    if cache = model_type.cache()
      return cache.findOrCreate(model_type.model_name, model_type, data)
    else
      return (model_type.findOrCreate(item) for item in data) if _.isArray(data)
      return new model_type(model_type::parse(data)) if _.isObject(data)
      related_model = new model_type({id: data})
      related_model._orm_needs_load = true
      return related_model

  model_type.cursor = (query={}) -> model_type._sync.cursor(query)

  model_type.destroy = (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1
    query = {id: query} unless _.isObject(query)
    model_type._sync.fn('destroy', query, callback)

  ###################################
  # Backbone ORM - Convenience Functions
  ###################################
  model_type.count = (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1
    model_type._sync.fn('cursor', query).count(callback)

  model_type.all = (callback) -> model_type._sync.fn('cursor', {}).toModels(callback)

  model_type.find = (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1
    model_type._sync.fn('cursor', query).toModels(callback)

  model_type.findOne = (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1
    query.$one = true
    model_type._sync.fn('cursor', query).toModels(callback)

  ###################################
  # Backbone ORM - Helpers
  ###################################
  model_type::cache = model_type.cache = -> model_type._cache
  model_type::schema = model_type.schema = -> model_type._sync.fn('schema')
  model_type::relation = model_type.relation = (key) -> model_type._sync.fn('relation', key)
  model_type::relationIsEmbedded = model_type.relationIsEmbedded = (key) -> return if relation = model_type._sync.fn('relation', key) then !!relation.embed else false

  ###################################
  # Backbone ORM - Model Overrides
  ###################################
  _original_initialize = model_type::initialize
  model_type::initialize = ->
    schema.initializeModel(@) if model_type.schema and (schema = model_type.schema())
    return _original_initialize.apply(@, arguments)

  _original_set = model_type::set
  model_type::set = (key, value, options) ->
    return _original_set.apply(@, arguments) unless model_type.schema and (schema = model_type.schema())

    if _.isString(key)
      (attributes = {})[key] = value;
    else
      attributes = key; options = value

    for key, value of attributes
      if relation = schema.relation(key)
        relation.set(@, key, value, options)
      else
        _original_set.call(@, key, value, options)
    return @

  _original_get = model_type::get
  model_type::get = (key, callback) ->
    schema = model_type.schema() if model_type.schema

    if schema and (relation = schema.relation(key))
      return relation.get(@, key, callback)
    else
      value = _original_get.call(@, key)
      callback(null, value) if callback
      return value

  _original_toJSON = model_type::toJSON
  model_type::toJSON = ->
    schema = model_type.schema() if model_type.schema

    return @get('id') if @_orm_json > 0
    @_orm_json or= 0
    @_orm_json++

    json = {}
    for key, value of @attributes

      if value instanceof Backbone.Collection
        if schema and (relation = schema.relation(key))
          relation.appendJSON(json, @, key)
        else
          json[key] = _.map(value.models, (model) -> if model then model.toJSON else null)

      else if value instanceof Backbone.Model
        if schema and (relation = schema.relation(key))
          relation.appendJSON(json, @, key)
        else
          json[key] = value.toJSON()

      else
        json[key] = JSONUtils.valueToJSON(value)

    delete @_orm_json if --@_orm_json is 0
    return json

  _original_save = model_type::save
  model_type::save = (key, value, options) ->
    throw new Error "Model is in a save loop: #{model_type.model_name}" if @_orm_save > 0
    @_orm_save or= 0
    @_orm_save++

    return _original_save.apply(@, arguments) unless model_type.schema and (schema = model_type.schema())

    # multiple signatures
    if key is null or _.isObject(key)
      attributes = key
      options = value
    else
      (attributes = {})[key] = value;

    options = Utils.bbCallback(options) if _.isFunction(options) # node style callback
    original_success = options.success
    original_error = options.error
    options = _.clone(options)
    options.success = (model, resp, options) =>
      delete @_orm_save if --@_orm_save is 0

      queue = new Queue(1) # TODO: in parallel?

      # now save relations
      for key, relation of schema.relations
        do (relation) => queue.defer (callback) => relation.save(@, key, callback)

      queue.await (err) =>
        return original_error?(@, new Error "Failed to save relations. #{err}") if err
        original_success?(model, resp, options)

    options.error = (model, resp, options) =>
      delete @_orm_save if --@_orm_save is 0
      original_error?(model, resp, options)

    return _original_save.call(@, attributes, options)

  model_type::cursor = (key, query) ->
    schema = model_type.schema() if model_type.schema
    if schema and (relation = schema.relation(key))
      return relation.cursor(@, key, query, callback)
    else
      throw new Error "#{schema.model_name}::cursor: Unexpected key: #{key} is not a relation"
