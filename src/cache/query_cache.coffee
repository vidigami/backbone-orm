###
  backbone-orm.js 0.5.2
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js, Underscore.js, Moment.js, and Inflection.js.
###

_ = require 'underscore'
inflection = require 'inflection'
Queue = require '../queue'

JSONUtils = require '../json_utils'
MemoryStore = require './memory_store'

CLONE_DEPTH = 2

module.exports = class QueryCache
  constructor: ->
    @enabled = false

  configure: (options={}) =>
    @enabled = options.enabled
    @verbose = options.verbose
    @hits = @misses = @clears = 0
    @store = options.store or new MemoryStore()
    return @

  cacheKey: (model_type, query) -> "#{model_type.model_id}_#{JSON.stringify(query)}"
  cacheKeyMeta: (model_type) -> "meta_#{model_type.model_id}"

  set: (model_type, query, related_model_types, value, callback) =>
    return callback() unless @enabled
    console.log 'QueryCache:set', model_type.model_name, (m.model_name for m in related_model_types), @cacheKey(model_type, query), JSON.stringify(value), '\n-----------' if @verbose

    model_types = [model_type].concat(related_model_types or [])
    cache_key = @cacheKey(model_type, query)
    @store.set cache_key, JSONUtils.deepClone(value, CLONE_DEPTH), (err) =>
      return callback(err) if err
      @storeKeyForModelTypes model_types, cache_key, callback

  get: (model_type, query, callback) =>
    return callback() unless @enabled
    @getKey(@cacheKey(model_type, query), callback)

  getKey: (key, callback) =>
    return callback() unless @enabled
    @store.get key, (err, value) =>
      return callback(err) if err
      if _.isUndefined(value) or _.isNull(value)
        @misses++
        console.log 'QueryCache:miss', key, value, '\n-----------' if @verbose
        callback()
      else
        @hits++
        console.log 'QueryCache:hit', key, value, '\n-----------' if @verbose
        callback(null, JSONUtils.deepClone(value, CLONE_DEPTH))

  getMeta: (model_type, callback) =>
    return callback() unless @enabled
    @store.get @cacheKeyMeta(model_type), callback

  hardReset: (callback) =>
    return callback() unless @enabled
    console.log 'QueryCache:hardReset' if @verbose
    @hits = @misses = @clears = 0
    return @store.reset(callback) if @store
    callback()

  reset: (model_types, callback) =>
    # clear the full cache
    return @hardReset(model_types) if arguments.length is 1

    return callback() unless @enabled
    model_types = [model_types] unless _.isArray(model_types)

    related_model_types = []
    related_model_types = related_model_types.concat(model_type.schema().allRelations()) for model_type in model_types
    model_types = model_types.concat(related_model_types)

    @clearModelTypes(model_types, callback)

  # Remove the model_types meta key then clear all cache keys depending on them
  clearModelTypes: (model_types, callback) =>
    return callback() unless model_types.length

    @getKeysForModelTypes model_types, (err, to_clear) =>
      return callback(err) if err

      queue = new Queue()
      queue.defer (callback) =>
        @clearMetaForModelTypes(model_types, callback)

      for key in _.uniq(to_clear)
        do (key) => queue.defer (callback) =>
          console.log 'QueryCache:cleared', key, '\n-----------' if @verbose
          @clears++
          @store.destroy(key, callback)

      queue.await callback

  # Clear the meta storage for given model types
  clearMetaForModelTypes: (model_types, callback) =>
    queue = new Queue()
    for model_type in model_types
      do (model_type) => queue.defer (callback) =>
        console.log 'QueryCache:meta cleared', model_type.model_name, '\n-----------' if @verbose
        @store.destroy @cacheKeyMeta(model_type), callback
    queue.await callback

  # Find all cache keys recorded as depending on the given model types
  getKeysForModelTypes: (model_types, callback) =>
    all_keys = []
    queue = new Queue(1)
    for model_type in model_types
      do (model_type) => queue.defer (callback) =>
        @getMeta model_type, (err, keys) =>
          return callback(err) if err or not keys
          all_keys = all_keys.concat(keys)
          callback()
    queue.await (err) -> callback(err, all_keys)

  # Add a key to the list of keys stored for a set of model types
  storeKeyForModelTypes: (model_types, cache_key, callback) =>
    queue = new Queue(1)
    for model_type in model_types
      do (model_type) => queue.defer (callback) =>
        model_type_key = @cacheKeyMeta(model_type)
        @store.get model_type_key, (err, keys) =>
          return callback(err) if err
          (keys or= []).push(cache_key)
          @store.set model_type_key, _.uniq(keys), callback
    queue.await callback
