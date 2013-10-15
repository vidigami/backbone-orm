_ = require 'underscore'
inflection = require 'inflection'
Queue = require 'queue-async'

Utils = require './../utils'
JSONUtils = require './../json_utils'

LRUStore = require './stores/lru'
MemoryStore = require './stores/memory'
RedisStore = require './stores/redis'

CLONE_DEPTH = 2

class QueryCache
  constructor: ->
    @enabled = false

  configure: (options={}) =>
    @enabled = options.enabled
    @verbose = options.verbose
    @hits = @misses = @clears = 0
    @store = options.store?() or new MemoryStore()
    return @

  cacheKey: (model_type, query) -> "#{_.result(model_type.prototype, 'url')}_#{JSON.stringify(query)}"

  set: (model_type, query, related_model_types, value, callback) =>
    return callback() unless @enabled
    console.log 'QueryCache:set', model_type.name, (m.name for m in related_model_types), @cacheKey(model_type, query), JSON.stringify(value), '\n-----------' if @verbose
    model_types = [model_type].concat(related_model_types or [])
    cache_key = @cacheKey(model_type, query)
    @store.set cache_key, {model_types: model_types, value: JSONUtils.deepClone(value, CLONE_DEPTH)}, (err) =>
      return callback(err) if err
      @storeKeyForModelTypes cache_key, model_types, callback

  _got: (model_type, query, value) =>
    unless _.isUndefined(value)
      @hits++
      console.log 'QueryCache:hit', @cacheKey(model_type, query), value, '\n-----------' if @verbose
    else
      @misses++
      console.log 'QueryCache:miss', @cacheKey(model_type, query), value, '\n-----------' if @verbose
    return JSONUtils.deepClone(value, CLONE_DEPTH)

  get: (model_type, query, callback) =>
    return callback() unless @enabled
    @store.get @cacheKey(model_type, query), (err, value) =>
      return callback(err) if err
      callback(null, @_got(model_type, query, value?.value))

  getRaw: (model_type, query, callback) =>
    return callback() unless @enabled
    @store.get @cacheKey(model_type, query), (err, value) =>
      return callback(err) if err
      callback(null, @_got(model_type, query, value))

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
    for model_type in model_types
      for key, relation of model_type.schema().relations
        related_model_types.push(relation.reverse_model_type)
        related_model_types.push(relation.join_table) if relation.join_table
    model_types = model_types.concat(related_model_types)

    # Clear everything depending on the given model_type(s)
    to_clear = []
#    @store.forEach (value, key, cache) =>
#      for model_type in model_types
#        to_clear.push(key) if model_type in value.model_types
#        console.log 'QueryCache:clear', model_type in value.model_types, (model_type.name), (m.name for m in value.model_types), key, JSON.stringify(value), '\n-----------' if @verbose

    queue = new Queue()
    for key in _.uniq(to_clear)
      do (key) => queue.defer (callback) =>
        @clears++
        @store.del(key, callback)

    queue.await callback

  count: => @store?.keys().length

module.exports = cache = new QueryCache()
