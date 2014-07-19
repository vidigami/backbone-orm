###
  backbone-orm.js 0.6.0
  Copyright (c) 2013-2014 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
###

Backbone = require 'backbone'
_ = require 'underscore'
Queue = require '../queue'

MemoryStore = require './memory_store'
MEMORY_STORE_KEYS = ['max', 'max_age', 'destroy']

module.exports = class ModelCache
  constructor: ->
    @enabled = false
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
  configure: (options={}) ->
    @enabled = options.enabled
    for key, value of options
      if _.isObject(value)
        @options[key] or= {}
        values = @options[key]
        values[value_key] = value_value for value_key, value_value of value
      else
        @options[key] = value
    @reset()

  configureSync: (model_type, sync_fn) ->
    return sync_fn if model_type::_orm_never_cache or not @createCache(model_type)
    return require('./sync')(model_type, sync_fn)

  reset: -> @createCache(value.model_type) for key, value of @caches

  # @nodoc
  createCache: (model_type) ->
    return null unless @enabled
    throw new Error "Missing model name for cache" unless model_name = model_type?.model_name

    # delete old cache
    if cache_info = @caches[model_name]
      delete @caches[model_name]; cache_info.cache.reset(); cache_info.model_type.cache = null

    # there are options meaning a cache should be created
    unless options = @options.modelTypes[model_name]
      return null unless (@options.store or @options.max or @options.max_age) # no options so no cache
      options = @options
    cache_info = @caches[model_name] = {cache: options.store?() or new MemoryStore(options), model_type: model_type}
    return model_type.cache = cache_info.cache
