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
    throw new Error "Cache is already configured" if @is_initialized # TODO: what to do with existing caches if the setting change
    @is_initialized = true

    for key, value of options
      key = inflection.camelize(inflection.underscore(key))
      if _.isObject(value)
        @options[key] or= {}
        values = @options[key]
        values[inflection.camelize(inflection.underscore(value_key))] = value_value for value_key, value_value of value
      else
        @options[key] = value

  get: (model_name, data) ->
    return undefined unless model_cache = @caches[model_name] # no caching

    if _.isArray(data) # many
      return (model_cache.get(item.id) for item in data)
    else # one
      return model_cache.get(data.id)

  getOrCreate: (model_name, model_type, data) ->
    model_cache = @caches[model_name] # no caching
    data = [data] unless many = _.isArray(data)
    models = ((model_cache and @get(item)) or Utils.dataToModel(model_type, item) for item in data)
    return if many then models else models[0]

  set: (model_name, data) ->
    return @ unless model_cache = @findOrCreateCache(model_name) # no caching

    data = [data] unless _.isArray(data)
    for item in data
      if cached_model = model_cache.get(item.id) # update existing
        if item instanceof Backbone.Model
          cached_model.set(item.toJSON())
        else if _.isObject(item)
          cached_model.set(item)
      model_cache.set(model.id, (cached_model or Utils.dataToModel(model_type, item)))
    return @

  del: (model_name, ids) ->
    return @ unless model_cache = @caches[model_name] # no caching

    ids = [ids] unless _.isArray(ids)
    model_cache.del(id) for id in ids
    return @

  reset: (model_name, ids) ->
    return @ unless model_cache = @caches[model_name] # no caching
    model_cache.reset()
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

# singleton
module.exports = new Cache()
