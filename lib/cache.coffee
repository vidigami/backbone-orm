util = require 'util'
Backbone = require 'backbone'
_ = require 'underscore'
inflection = require 'inflection'
LRU = require 'lru-cache'

Utils = require './utils'

# @private
class Cache
  constructor: ->
    @caches = {}
    @options = {modelTypes: {}}

  # Configure the cache singleton
  #
  # options:
  #   max: default maximum number of items or max size of the cache
  #   max_age/maxAge: default maximum number of items or max size of the cache
  #   model_types/modelTypes: {'ModelName': options}
  #
  configure: (options) ->
    @reset()
    (@options = {modelTypes: {}}; return @) unless options # clear all options

    for key, value of options
      key = @normalizeKey(key)
      if _.isObject(value)
        @options[key] or= {}
        values = @options[key]
        values[@normalizeKey(value_key)] = value_value for value_key, value_value of value
      else
        @options[key] = value
    return @

  configureSync: (model_type, sync_fn) ->
    return if @findOrCreateCache(model_type.model_name) then require('./cache_sync')(model_type, sync_fn) else sync_fn

  reset: (model_name, ids) ->
    # clear the full cache
    if arguments.length is 0
      value.reset() for key, value of @caches
      @caches = {}

    # clear a model cache
    else if arguments.length is 1
      return @ unless model_cache = @caches[model_name] # no caching
      model_cache.reset()

    # clear specific ids from a model cache
    else
      ids = [ids] unless _.isArray(ids)
      model_cache.del(id) for id in ids
    return @

  get: (model_name, data) ->
    return undefined unless model_cache = @caches[model_name] # no caching
    return if _.isArray(data) then (model_cache.get(item.id) for item in data) else model_cache.get(data.id)

  getOrCreate: (model_name, model_type, data) ->
    model_cache = @caches[model_name] # no caching
    data = [data] unless many = _.isArray(data)
    models = ((model_cache and @get(item)) or Utils.dataToModel(model_type, item) for item in data)
    return if many then models else models[0]

  set: (model_name, model_type, data) ->
    return @ unless model_cache = @findOrCreateCache(model_name) # no caching

    data = [data] unless _.isArray(data)
    for item in data
      continue unless (item and item.id)
      if cached_model = model_cache.get(item.id) # update existing
        cached_json = cached_model.toJSON()
        if item instanceof Backbone.Model
          cached_model.set(item_json) if (cached_model isnt item) and not _.isEqual(cached_json, item_json = item.toJSON())
        else if _.isObject(item)
          cached_model.set(item) if not _.isEqual(cached_json, item)
      model_cache.set(item.id, (cached_model or Utils.dataToModel(model_type, item)))
    return @

  del: (model_name, ids) ->
    return @ unless model_cache = @caches[model_name] # no caching

    ids = [ids] unless _.isArray(ids)
    model_cache.del(id) for id in ids
    return @

  findOrCreateCache: (model_name) ->
    return model_cache if model_cache = @caches[model_name]

    # there are options
    if options = @options.modelTypes[model_name]
      return @caches[model_name] = LRU(options)

    # there are global options
    else if @options.max or @options.maxAge
      return @caches[model_name] = LRU(_.pick(@options, 'max', 'maxAge', 'length', 'dispose', 'stale'))

    return null

  normalizeKey: (key) ->
    key = inflection.underscore(key)
    return key.toLowerCase() if key.indexOf('_') < 0
    return inflection.camelize(key)

# singleton
module.exports = new Cache()
