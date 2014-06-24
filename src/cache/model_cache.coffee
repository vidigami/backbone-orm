###
  backbone-orm.js 0.5.17
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
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
    @reset(->)
    for key, value of options
      if _.isObject(value)
        @options[key] or= {}
        values = @options[key]
        values[value_key] = value_value for value_key, value_value of value
      else
        @options[key] = value
    return @

  configureSync: (model_type, sync_fn) ->
    return sync_fn if model_type::_orm_never_cache or not (cache = @getOrCreateCache(model_type.model_name))
    model_type.cache = cache
    return require('./sync')(model_type, sync_fn)

  reset: (callback) ->
    queue = new Queue()
    for key, value of @caches
      do (value) -> queue.defer (callback) -> value.reset(callback)
    queue.await callback

  hardReset: ->
    @reset(->)
    delete @caches[key] for key, value of @caches
    return @

  # @nodoc
  getOrCreateCache: (model_name) ->
    return null unless @enabled
    throw new Error "Missing model name for cache" unless model_name
    return model_cache if model_cache = @caches[model_name]

    # there are options
    if options = @options.modelTypes[model_name]
      return @caches[model_name] = options.store?() or new MemoryStore(_.pick(options, MEMORY_STORE_KEYS))

    # there are global options
    else if @options.store or @options.max or @options.max_age
      return @caches[model_name] = @options.store?() or new MemoryStore(_.pick(@options, MEMORY_STORE_KEYS))

    return null
