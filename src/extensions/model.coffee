###
  backbone-orm.js 0.7.14
  Copyright (c) 2013-2016 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

_ = require 'underscore'
Backbone = require 'backbone'

Queue = require '../lib/queue'
Utils = require '../lib/utils'
JSONUtils = require '../lib/json_utils'
DatabaseURL = require '../lib/database_url'

ModelStream = require './model_stream'
modelEach = require './model_each'
modelInterval = require './model_interval'
require './collection' # ensure collection extensions are loaded

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
  #   Destroy a each of models by query.
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
  # @method .each(query, iterator, callback)
  #   Fetch a batch of models at a time and process them.
  #
  # @method .stream(query)
  #   Fetch a batch of models at a time and process them.
  #
  # @method .interval(query, iterator, callback)
  #   Process a each of models in fixed-size time intervals. For example, if map-reducing in fixed intervals.
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

  model_type.db = -> model_type::sync('db')

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
    throw 'findOrCreate requires object data' if not _.isObject(data) or Utils.isModel(data) or Utils.isCollection(data)

    query = _.extend({$one: true}, data)
    model_type::sync('cursor', query).toModels (err, model) ->
      return callback(err) if err
      return callback(null, model) if model
      (new model_type(data)).save callback

  model_type.findOneNearestDate = (date, options, query, callback) ->
    throw new Error "Missing options key" unless key = options.key

    if arguments.length is 2
      [query, callback] = [{}, query]
    else if arguments.length is 3
      [options, query, callback] = [new Date(), {}, query]
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

  model_type.each = (query, iterator, callback) ->
    [query, iterator, callback] = [{}, query, iterator] if arguments.length is 2
    modelEach(model_type, query, iterator, callback)

  model_type.eachC = (query, callback, iterator) ->
    [query, callback, iterator] = [{}, query, callback] if arguments.length is 2
    modelEach(model_type, query, iterator, callback)

  model_type.stream = (query={}) ->
    throw new Error 'Stream is a large dependency so you need to manually include "stream.js" in the browser.' unless _.isFunction(ModelStream)
    return new ModelStream(model_type, query)

  model_type.interval = (query, iterator, callback) -> modelInterval(model_type, query, iterator, callback)
  model_type.intervalC = (query, callback, iterator) -> modelInterval(model_type, query, iterator, callback)

  ###################################
  # Backbone ORM - Helpers
  ###################################

  model_type::modelName = -> return model_type.model_name
  model_type::cache = -> model_type.cache
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
    (delete needs_load[key]; return) if is_loaded and Utils.get(@, 'is_initialized') # after initialized, delete needs_load
    needs_load[key] = !is_loaded

  model_type::isLoadedExists = (key) ->
    key = '__model__' if arguments.length is 0
    Utils.orSet(@, 'needs_load', {}).hasOwnProperty(key)

  model_type::isPartial = ->
    !!Utils.get(@, 'partial')

  model_type::setPartial = (is_partial) ->
    if is_partial then Utils.set(@, 'partial', true) else Utils.unset(@, 'partial')

  model_type::addUnset = (key) ->
    unsets = Utils.orSet(@, 'unsets', [])
    unsets.push(key) if unsets.indexOf(key) < 0

  model_type::removeUnset = (key) ->
    return unless unsets = Utils.get(@, 'unsets', null)
    unsets.splice(index, 1) if (index = unsets.indexOf(key)) >= 0

  ###################################
  # Backbone ORM - Model Lifecyle
  ###################################

  model_type::fetchRelated = (relations, callback) ->
    [relations, callback] = [null, relations] if arguments.length is 1

    queue = new Queue(1)
    queue.defer (callback) => if @isLoaded() then callback() else @fetch(callback)
    queue.defer (callback) =>
      keys = _.keys(Utils.orSet(@, 'needs_load', {}))
      relations = [relations] if relations and not _.isArray(relations)
      keys = _.intersection(keys, relations) if _.isArray(relations)
      Utils.each keys, ((key, callback) => @get(key, callback)), callback

    queue.await callback

  model_type::patchAdd = (key, relateds, callback) ->
    return callback(new Error("patchAdd: relation '#{key}' unrecognized")) unless relation = @relation(key)
    return callback(new Error("patchAdd: missing relateds for '#{key}'")) unless relateds
    return relation.patchAdd(@, relateds, callback)

  model_type::patchRemove = (key, relateds, callback) ->
    if arguments.length is 1
      callback = key
      schema = model_type.schema()

      queue = new Queue(1)
      for key, relation of schema.relations
        do (relation) => queue.defer (callback) => relation.patchRemove(@, callback)
      queue.await callback

    else
      return callback(new Error("patchRemove: relation '#{key}' unrecognized")) unless relation = @relation(key)
      if arguments.length is 2
        callback = relateds
        relation.patchRemove(@, callback)

      else
        return callback(new Error("patchRemove: missing relateds for '#{key}'")) unless relateds
        return relation.patchRemove(@, relateds, callback)

  ###################################
  # Backbone ORM - Relationship Query
  ###################################
  model_type::cursor = (key, query={}) ->
    schema = model_type.schema() if model_type.schema
    if schema and (relation = schema.relation(key))
      return relation.cursor(@, key, query)
    else
      throw new Error "#{schema.model_name}::cursor: Unexpected key: #{key} is not a relation"

  ###################################
  # Backbone ORM - Model Overrides
  ###################################

  # clone helper
  _findOrClone = (model, options) ->
    return model.clone(options) if model.isNew() or not model.modelName
    cache = options._cache[model.modelName()] or= {}
    unless clone = cache[model.id]
      clone = model.clone(options)
      cache[model.id] = clone if model.isLoaded()
    return clone

  overrides =
    initialize: (attributes) ->
      if model_type.schema and (schema = model_type.schema())
        relation.initializeModel(@) for key, relation of schema.relations

        # mark as initialized and clear out needs_load flags
        needs_load = Utils.orSet(@, 'needs_load', {})
        delete needs_load[key] for key, value of needs_load when !value
        Utils.set(@, 'is_initialized', true)

        # TODO: add to the cache -> would need to check that all relationships are loaded and set self as loaded?
        # model_type.cache.set(@id, @) if model_type.cache and @id and attributes and _.size(attributes) > 1 # assume it is loaded

      return model_type::_orm_original_fns.initialize.apply(@, arguments)

    fetch: (options) ->
      # callback signature
      if _.isFunction(callback = arguments[arguments.length-1])
        switch arguments.length
          when 1 then options = Utils.wrapOptions({}, callback)
          when 2 then options = Utils.wrapOptions(options, callback)
      else
        options or= {}

      return model_type::_orm_original_fns.fetch.call(@, Utils.wrapOptions(options, (err, model, resp, options) =>
        return options.error?(@, resp, options) if err
        @setLoaded(true)
        options.success?(@, resp, options)
      ))

    unset: (key) ->
      @addUnset(key)
      id = @id
      model_type::_orm_original_fns.unset.apply(@, arguments)
      model_type.cache.destroy(id) if key is 'id' and model_type.cache and id and (model_type.cache.get(id) is @) # clear us from the cache

    set: (key, value, options) ->
      return model_type::_orm_original_fns.set.apply(@, arguments) unless model_type.schema and (schema = model_type.schema())

      if _.isString(key)
        (attributes = {})[key] = value;
      else
        attributes = key; options = value

      # first set simple attributes
      simple_attributes = {}
      relational_attributes = {}
      for key, value of attributes
        if relation = schema.relation(key)
          relational_attributes[key] = relation
        else
          simple_attributes[key] = value
      model_type::_orm_original_fns.set.call(@, simple_attributes, options) if !JSONUtils.isEmptyObject(simple_attributes)

      # then set relationships
      relation.set(@, key, attributes[key], options) for key, relation of relational_attributes

      # model_type.cache.set(@id, @) if model_type.cache and @isLoaded() and @id # update the cache: TODO: look at the partial models code
      return @

    get: (key, callback) ->
      schema = model_type.schema() if model_type.schema

      return relation.get(@, key, callback) if schema and (relation = schema.relation(key))
      value = model_type::_orm_original_fns.get.call(@, key)
      callback(null, value) if callback
      return value

    toJSON: (options={}) ->
      schema = model_type.schema() if model_type.schema

      @_orm or= {}
      return @id if @_orm.json > 0
      @_orm.json or= 0; @_orm.json++

      json = {}
      keys = options.keys or @whitelist or _.keys(@attributes)
      for key in keys
        value = @attributes[key]
        if schema and (relation = schema.relation(key))
          relation.appendJSON(json, @)

        else if Utils.isCollection(value)
          json[key] = _.map(value.models, (model) -> if model then model.toJSON(options) else null)

        else if Utils.isModel(value)
          json[key] = value.toJSON(options)

        else
          json[key] = value

      --@_orm.json
      return json

    # callback possible
    save: (key, value, options) ->
      # callback signature
      if _.isFunction(callback = arguments[arguments.length-1])
        switch arguments.length
          when 1 then attributes = {}; options = Utils.wrapOptions({}, callback)
          when 2 then attributes = key; options = Utils.wrapOptions({}, callback)
          when 3 then attributes = key; options = Utils.wrapOptions(value, callback)
          when 4 then (attributes = {})[key] = value; options = Utils.wrapOptions(options, callback)
      else
        if arguments.length is 0
          attributes = {}; options = {}
        else if key is null or _.isObject(key)
          attributes = key; options = value
        else
          (attributes = {})[key] = value;

      return options.error?(@, new Error "An unloaded model is trying to be saved: #{model_type.model_name}") unless @isLoaded()

      @_orm or= {}
      if @_orm.save > 0
        return options.success?(@, {}, options) if @id # has an id so should be safe for relationships
        return options.error?(@, new Error "Model is in a save loop: #{model_type.model_name}")
      @_orm.save or= 0; @_orm.save++

      # set the attributes
      @set(attributes, options)
      attributes = {}

      Utils.presaveBelongsToRelationships @, (err) =>
        return options.error?(@, err) if err

        return model_type::_orm_original_fns.save.call(@, attributes, Utils.wrapOptions(options, (err, model, resp, options) =>
          Utils.unset(@, 'unsets'); --@_orm.save
          return options.error?(@, resp, options) if err
          queue = new Queue(1)

          # now save relations
          if model_type.schema
            schema = model_type.schema()
            for key, relation of schema.relations
              do (relation) => queue.defer (callback) => relation.save(@, callback)

          queue.await (err) =>
            return options.error?(@, Error "Failed to save relations. #{err}", options) if err
            cache.set(@id, @) if cache = model_type.cache # update the cache
            options.success?(@, resp, options)
        ))

    destroy: (options) ->
      # callback signature
      if _.isFunction(callback = arguments[arguments.length-1])
        switch arguments.length
          when 1 then options = Utils.wrapOptions({}, callback)
          when 2 then options = Utils.wrapOptions(options, callback)

      cache.destroy(@id) if cache = @cache() # clear out of the cache
      return model_type::_orm_original_fns.destroy.call(@, options) unless model_type.schema and (schema = model_type.schema())

      @_orm or= {}
      throw new Error "Model is in a destroy loop: #{model_type.model_name}" if @_orm.destroy > 0
      @_orm.destroy or= 0; @_orm.destroy++

      return model_type::_orm_original_fns.destroy.call(@, Utils.wrapOptions(options, (err, model, resp, options) =>
        --@_orm.destroy
        return options.error?(@, resp, options) if err

        @patchRemove (err) =>
          return options.error?(@, new Error "Failed to destroy relations. #{err}", options) if err
          options.success?(@, resp, options)
      ))

    clone: (options) ->
      return model_type::_orm_original_fns.clone.apply(@, arguments) unless model_type.schema

      options or= {}
      options._cache or= {}
      cache = options._cache[@modelName()] or= {}

      @_orm or= {}
      if @_orm.clone > 0 # TODO: how to handle recursion
        return if @id then cache[@id] else model_type::_orm_original_fns.clone.apply(@, arguments)
      @_orm.clone or= 0; @_orm.clone++

      # create a shell to refer to
      if @id
        unless clone = cache[@id]
          clone = new @constructor()
          cache[@id] = clone if @isLoaded()
      else
        clone = new @constructor()
      clone.id = @attributes.id if @attributes.id

      keys = options.keys or _.keys(@attributes)
      for key in keys
        value = @attributes[key]
        if Utils.isCollection(value)
          clone.attributes[key] = new value.constructor() unless clone.attributes[key]?.values
          clone.attributes[key].reset(_findOrClone(model, options) for model in value.models)

        else if Utils.isModel(value)
          clone.attributes[key] = _findOrClone(value, options)

        else
          clone.attributes[key] = value

      --@_orm.clone
      return clone

  if not model_type::_orm_original_fns
    model_type::_orm_original_fns = {}
    for key, fn of overrides
      model_type::_orm_original_fns[key] = model_type::[key]
      model_type::[key] = fn
