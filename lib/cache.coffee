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
    @verbose = false
    # @verbose = true

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
    return if @getOrCreateModelCache(model_type.model_name) then require('./cache_sync')(model_type, sync_fn) else sync_fn

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
    return (model_cache.get(item.id) for item in data) if _.isArray(data)
    model = model_cache.get(Utils.dataId(data))
    console.log "Cache (#{model_name}) #{if !!model then 'hit' else 'miss'}: #{Utils.dataId(data)}" if @verbose
    return model

  set: (model_name, model) ->
    return @ unless model_cache = @getOrCreateModelCache(model_name) # no caching
    if current_model = model_cache.get(model.id)
      @updateModel(current_model, model)
    else
      model_cache.set(model.id, model)
    return @

  del: (model_name, ids) ->
    return @ unless model_cache = @caches[model_name] # no caching

    ids = [ids] unless _.isArray(ids)
    model_cache.del(id) for id in ids
    return @

  getOrCreateModelCache: (model_name) ->
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

  updateModel: (model, data) ->
    return if model is data
    model_json = model.toJSON()
    if data instanceof Backbone.Model
      model.set(data_json) if not _.isEqual(model_json, data_json = data.toJSON())
    else if _.isObject(data)
      model.set(data) if not _.isEqual(model_json, data)

# singleton
module.exports = new Cache()
