util = require 'util'
_ = require 'underscore'
Backbone = require 'backbone'
moment = require 'moment'
Queue = require 'queue-async'

Utils = require './utils'

module.exports = (model_type) ->

  # Extensions to the base Backbone.Model class
  #
  # @method .resetSchema(options, callback)
  #   Create the database collections or tables while deleting all existing data.
  #
  # @method .cursor(query={})
  #   Create a cursor for iterating over models or JSON.
  #
  # @method .destroy(query, callback)
  #   Destroy a batch of models by query.
  #
  # @method .exists(query, callback)
  #   Helper method to check if at least one model exists that matches the query (or with no query, if there is at least one model).
  #
  # @method .count(query, callback)
  #   Helper method for counting Models matching a query.
  #
  # @method .all(callback)
  #   Helper method for processing all Models.
  #
  # @method .find(query, callback)
  #   Find models by query.
  #
  # @method .findOne(query, callback)
  #   Helper method for finding a single model.
  #
  # @method .findOrCreate(data, callback)
  #   Find a model by data (including the id) or create with save if it does not already exist.
  #
  # @method .findOrNew(data, callback)
  #   Find a model by data (including the id) or create a new one without save if it does not already exist.
  #
  # @method .findOneNearestDate(date, options, query, callback)
  #   Find a model near a date. It will search in both directions until a model is found depending on the reverse flag (default is forwards).
  #   @param [Object] options
  #   @option reverse [String] Start searching backwards from the given date.
  #
  # @method .batch(query, options, callback, fn)
  #   Fetch a batch of models at a time and process them.
  #
  # @method .interval(query, options, callback, fn)
  #   Process a batch of models in fixed-size time intervals. For example, if map-reducing in fixed intervals.
  #
  # @method #modelName()
  #   Get a model name from a model instance.
  #
  # @method #cursor(key, query={})
  #   Create a cursor for a model's relationship.
  #
  class BackboneModelExtensions

  ###################################
  # Backbone ORM - Sync Accessors
  ###################################

  model_type.createSync = (target_model_type, cache) -> model_type::sync('createSync', target_model_type, cache)

  ###################################
  # Backbone ORM - Class Extensions
  ###################################

  model_type.resetSchema = (options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 1
    model_type::sync('resetSchema', options, callback)

  model_type.cursor = (query={}) -> model_type::sync('cursor', query)

  model_type.destroy = (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1
    query = {id: query} unless _.isObject(query)
    model_type::sync('destroy', query, callback)

  ###################################
  # Backbone ORM - Convenience Functions
  ###################################

  model_type.exists = (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1
    model_type::sync('cursor', query).exists(callback)

  model_type.count = (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1
    model_type::sync('cursor', query).count(callback)

  model_type.all = (callback) -> model_type::sync('cursor', {}).toModels(callback)

  model_type.find = (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1
    model_type::sync('cursor', query).toModels(callback)

  model_type.findOne = (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1
    query = if _.isObject(query) then _.extend({$one: true}, query) else {id: query, $one: true}
    model_type::sync('cursor', query).toModels(callback)

  model_type.findOrCreate = (data, callback) ->
    throw 'findOrCreate requires object data' if not _.isObject(data) or (data instanceof Backbone.Model) or (data instanceof Backbone.Collection)

    query = _.extend({$one: true}, data)
    model_type::sync('cursor', query).toModels (err, model) ->
      return callback(err) if err
      return callback(null, model) if model
      model = new model_type(data)
      model.save {}, (err) ->
        return callback(err) if err
        cache.add(model_type.model_name, model) if cache = model_type.cache()
        callback(null, model)

  model_type.findOrNew = (data) ->
    throw 'findOrNew requires data' unless data
    return data if (data instanceof Backbone.Model) or (data instanceof Backbone.Collection)

    if cache = model_type.cache()
      return cache.findOrNew(model_type.model_name, model_type, data)
    else
      return (model_type.findOrNew(item) for item in data) if _.isArray(data)
      return new model_type(model_type::parse(data)) if _.isObject(data)
      related_model = new model_type({id: data})
      related_model._orm_needs_load = true
      return related_model

  model_type.findOneNearestDate = (date, options, query, callback) ->
    throw new Error "Missing options key" unless key = options.key

    if arguments.length is 2
      [query, callback] = [{}, query]
    else if arguments.length is 3
      [options, query, callback] = [moment.utc().toDate(), {}, query]
    else
      query = _.clone(query)
    query.$one = true

    functions = [
      ((callback) =>
        query[key] = {$lte: date}
        model_type.cursor(query).sort("-#{key}").toModels callback),
      ((callback) =>
        query[key] = {$gte: date}
        model_type.cursor(query).sort(key).toModels callback)
    ]

    functions = [functions[1], functions[0]] if options.reverse
    functions[0] (err, model) ->
      return callback(err) if err
      return callback(null, model) if model
      functions[1] callback

  model_type.batch = (query, options, callback, fn) ->
    args = _.toArray(arguments)
    args.unshift({}) while args.length < 4
    args.unshift(model_type)
    Utils.batch.apply(null, args)

  model_type.interval = (query, options, callback, fn) ->
    args = _.toArray(arguments)
    args.unshift({}) while args.length < 4
    args.unshift(model_type)
    Utils.interval.apply(null, args)

  ###################################
  # Backbone ORM - Helpers
  ###################################

  model_type::cache = model_type.cache = -> model_type::sync('cache')
  model_type::schema = model_type.schema = -> model_type::sync('schema')
  model_type::relation = model_type.relation = (key) -> if schema = model_type::sync('schema') then schema.relation(key) else return undefined
  model_type::relationIsEmbedded = model_type.relationIsEmbedded = (key) -> return if relation = model_type.relation(key) then !!relation.embed else false

  ###################################
  # Backbone ORM - Model Overrides
  ###################################

  _original_initialize = model_type::initialize
  model_type::initialize = ->
    schema.initializeModel(@) if model_type.schema and (schema = model_type.schema())
    return _original_initialize.apply(@, arguments)

  model_type::modelName = -> return model_type.model_name

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
  model_type::toJSON = (options={}) ->
    schema = model_type.schema() if model_type.schema

    return @id if @_orm_json > 0
    @_orm_json or= 0
    @_orm_json++

    json = {}
    attributes = if @whitelist then _.pick(@attributes, @whitelist) else @attributes
    for key, value of attributes
      if schema and (relation = schema.relation(key))
        relation.appendJSON(json, @, key)

      else if value instanceof Backbone.Collection
        json[key] = _.map(value.models, (model) -> if model then model.toJSON(options) else null)

      else if value instanceof Backbone.Model
        json[key] = value.toJSON(options)

      else
        json[key] = value

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

  _original_clone = model_type::clone
  model_type::clone = (key, value, options) ->
    return _original_clone.apply(@, arguments) unless model_type.schema and (schema = model_type.schema())

    return @id if @_orm_clone > 0
    @_orm_clone or= 0
    @_orm_clone++

    json = {}
    for key, value of @attributes

      if value instanceof Backbone.Collection
        json[key] = new value.constructor(model.clone() for model in value.models)

      else if value instanceof Backbone.Model
        json[key] = value.clone()

      else
        json[key] = value

    delete @_orm_clone if --@_orm_clone is 0
    return new @constructor(json)

  model_type::cursor = (key, query={}) ->
    schema = model_type.schema() if model_type.schema
    if schema and (relation = schema.relation(key))
      return relation.cursor(@, key, query)
    else
      throw new Error "#{schema.model_name}::cursor: Unexpected key: #{key} is not a relation"
