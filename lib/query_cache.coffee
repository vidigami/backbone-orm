util = require 'util'
_ = require 'underscore'
inflection = require 'inflection'
LRU = require 'lru-cache'

Utils = require './utils'

# @private
class QueryCache
  constructor: ->
    @enabled = false

  configure: (@options={}) =>
    @enabled = options.enabled
    @verbose = options.verbose

    @hardReset() # Clear previous cache, reset counts

    lru_options = {}
    for key, value of options
      key = @normalizeKey(key)
      lru_options[key] = value

    @cache = new LRU(lru_options)
    return @

  cacheKey: (model_type, query) -> "#{_.result(model_type.prototype, 'url')}_#{JSON.stringify(query)}"

  set: (model_type, query, related_model_types, value) =>
    return @ unless @enabled
    if @verbose
      console.log '*SET', model_type.name, (m.name for m in related_model_types), @cacheKey(model_type, query), JSON.stringify(value)
      console.log '-----------'
    model_types = [model_type].concat(related_model_types or [])
    @cache.set(@cacheKey(model_type, query), {model_types: model_types, value: value})
    return @

  _got: (model_type, query, value) =>
    if value
      @hits++
      if @verbose
        console.log '+HIT', @cacheKey(model_type, query), value, '\n-----------'
    else
      if @verbose
        console.log '-MISS', @cacheKey(model_type, query), value, '\n-----------'
      @misses++
    return value

  get: (model_type, query) =>
    return null unless @enabled
    return @_got(model_type, query, @cache.get(@cacheKey(model_type, query))?.value)

  getRaw: (model_type, query) =>
    return null unless @enabled
    return @_got(model_type, query, @cache.get(@cacheKey(model_type, query)))

  hardReset: =>
    console.log 'RESET ALL' if @verbose
    @cache?.reset()
    @hits = @misses = @clears = 0
    return @

  reset: (model_types) =>
    return @ unless @enabled

    # clear the full cache
    return @hardReset() unless model_types

    model_types = [model_types] unless _.isArray(model_types)

    related_model_types = []
    for model_type in model_types
      for key, relation of model_type.schema().relations
        related_model_types.push(relation.reverse_model_type)
        related_model_types.push(relation.join_table) if relation.join_table
    model_types = model_types.concat(related_model_types)

#    console.log 'clearing', @cache.keys().length, (m.name for m in model_types)

    to_clear = []
    pre_clears = @clears
    # Clear everything depending on the given model_type
    @cache.forEach (value, key, cache) =>
      for model_type in model_types
        to_clear.push(key) if model_type in value.model_types
        if @verbose
          console.log 'CLEARED?', (model_type.name), (m.name for m in value.model_types), model_type in value.model_types, key, JSON.stringify(value)
          console.log '-----------'

    for key in _.uniq(to_clear)
      @clears++
      @cache.del(key)

#    console.log 'c', cleard, @cache.keys().length
    return @

  count: => @cache?.keys().length

  normalizeKey: (key) -> inflection.camelize(key)

module.exports = cache = new QueryCache()

#cache.configure({enabled: true})
