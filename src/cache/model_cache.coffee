###
  backbone-orm.js 0.7.14
  Copyright (c) 2013-2016 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

Backbone = require 'backbone'
_ = require 'underscore'
Queue = require '../lib/queue'

MemoryStore = require './memory_store'

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
    return (require './sync')(model_type, sync_fn)

  reset: -> @createCache(value.model_type) for key, value of @caches

  # @nodoc
  createCache: (model_type) ->
    throw new Error "Missing model name for cache" unless model_name = model_type?.model_name
    cuid = model_type.cuid or= _.uniqueId('cuid')

    # delete old cache
    if cache_info = @caches[cuid]
      delete @caches[cuid]; cache_info.cache.reset(); cache_info.model_type.cache = null
    return null unless @enabled

    # there are options meaning a cache should be created
    unless options = @options.modelTypes[model_name]
      return null unless (@options.store or @options.max or @options.max_age) # no options so no cache
      options = @options
    cache_info = @caches[cuid] = {cache: options.store?() or new MemoryStore(options), model_type: model_type}
    return model_type.cache = cache_info.cache
