util = require 'util'
_ = @_ or require 'underscore'
Backbone = @Backbone or require 'backbone'
JSONUtils = require './json_utils'
Queue = require 'queue-async'

module.exports = (model_type, sync) ->

  ###################################
  # Backbone ORM - Sync Accessors
  ###################################
  model_type.sync = -> sync('sync')
  model_type.createSync = (model_type, cache) -> sync.apply(null, ['createSync'].concat(_.toArray(arguments)))

  ###################################
  # Backbone ORM - Class Extensions
  ###################################
  model_type.cursor = (query={}) -> sync('cursor', query)

  model_type.destroy = (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1
    query = {id: query} unless _.isObject(query)
    sync('destroy', query, callback)

  ###################################
  # Backbone ORM - Convenience Functions
  ###################################
  model_type.count = (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1
    sync('cursor', query).count(callback)

  model_type.all = (callback) -> sync('cursor', {}).toModels(callback)

  model_type.find = (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1
    sync('cursor', query).toModels(callback)

  ###################################
  # Backbone ORM - Helpers
  ###################################
  model_type::cache = model_type.cache = -> model_type._cache
  model_type::schema = model_type.schema = -> sync('schema')
  model_type::relation = model_type.relation = (key) -> sync('relation', key)
  model_type::relationIsEmbedded = model_type.relationIsEmbedded = (key) -> return if relation = sync('relation', key) then !!relation.embed else false

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
