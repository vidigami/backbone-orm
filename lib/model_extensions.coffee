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

  model_type.createSync = (target_model_type) -> model_type::sync('createSync', target_model_type)

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
        cache.set(model.id, model) if cache = model_type.cache
        callback(null, model)

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

  model_type::cache = -> model_type.cache
  model_type::tableName = model_type.tableName = -> model_type::sync('tableName')
  model_type::schema = model_type.schema = -> model_type::sync('schema')
  model_type::tableName = model_type.tableName = -> model_type::sync('tableName')
  model_type::relation = model_type.relation = (key) -> if schema = model_type::sync('schema') then schema.relation(key) else return undefined
  model_type::relationIsEmbedded = model_type.relationIsEmbedded = (key) -> return if relation = model_type.relation(key) then !!relation.embed else false
  model_type::reverseRelation = model_type.reverseRelation = (key) -> if schema = model_type::sync('schema') then schema.reverseRelation(key) else return undefined

  model_type::isLoaded = (key) ->
    key = '__model__' if arguments.length is 0
    not Utils.orSet(@, 'needs_load', {})[key]

  model_type::setLoaded = (key, is_loaded) ->
    [key, is_loaded] = ['__model__', key] if arguments.length is 1
    needs_load = Utils.orSet(@, 'needs_load', {})
    return delete needs_load[key] if is_loaded
    needs_load[key] = true

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

    return relation.get(@, key, callback) if schema and (relation = schema.relation(key))
    value = _original_get.call(@, key)
    callback(null, value) if callback
    return value

  _original_toJSON = model_type::toJSON
  model_type::toJSON = (options={}) ->
    schema = model_type.schema() if model_type.schema

    @_orm or= {}
    return @id if @_orm.json > 0
    @_orm.json or= 0; @_orm.json++

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

    --@_orm.json
    return json

  _original_save = model_type::save
  model_type::save = (key, value, options) ->
    return _original_save.apply(@, arguments) unless model_type.schema and (schema = model_type.schema())

    # multiple signatures
    if key is null or _.isObject(key)
      attributes = key
      options = value
    else
      (attributes = {})[key] = value;

    @_orm or= {}
    # throw new Error "Model is in a save loop: #{model_type.model_name}" if @_orm.save > 0
    return options.success(@, {}, options) if @_orm.save > 0
    @_orm.save or= 0; @_orm.save++

    return _original_save.call(@, attributes, Utils.wrapOptions(options, (err, model, resp, options) =>
      --@_orm.save
      return options.error?(@, resp, options) if err

      queue = new Queue(1)

      # now save relations
      for key, relation of schema.relations
        do (relation) => queue.defer (callback) => relation.save(@, key, callback)

      queue.await (err) =>
        return options.error?(@, Error "Failed to save relations. #{err}", options) if err
        options.success?(@, resp, options)
    ))

  _original_destroy = model_type::destroy
  model_type::destroy = (options) ->
    cache.del(@id) if cache = @cache() # clear out of the cache
    return _original_destroy.apply(@, arguments) unless model_type.schema and (schema = model_type.schema())

    @_orm or= {}
    throw new Error "Model is in a destroy loop: #{model_type.model_name}" if @_orm.destroy > 0
    @_orm.destroy or= 0; @_orm.destroy++

    return _original_destroy.call(@, Utils.wrapOptions(options, (err, model, resp, options) =>
      --@_orm.destroy
      return options.error?(@, resp, options) if err

      queue = new Queue(1)

      # now remove relations
      for key, relation of schema.relations
        do (relation) => queue.defer (callback) => relation.destroy(@, callback)

      queue.await (err) =>
        return options.error?(@, new Error "Failed to destroy relations. #{err}", options) if err
        options.success?(model, resp, options)
    ))

  _original_clone = model_type::clone
  model_type::clone = (key, value, options) ->
    return _original_clone.apply(@, arguments) unless model_type.schema and (schema = model_type.schema())

    @_orm or= {}
    return @id if @_orm.clone > 0
    @_orm.clone or= 0; @_orm.clone++

    json = {}
    for key, value of @attributes

      if value instanceof Backbone.Collection
        json[key] = new value.constructor(model.clone() for model in value.models)

      else if value instanceof Backbone.Model
        json[key] = value.clone()

      else
        json[key] = value

    --@_orm.clone
    return new @constructor(json)

  model_type::cursor = (key, query={}) ->
    schema = model_type.schema() if model_type.schema
    if schema and (relation = schema.relation(key))
      return relation.cursor(@, key, query)
    else
      throw new Error "#{schema.model_name}::cursor: Unexpected key: #{key} is not a relation"
