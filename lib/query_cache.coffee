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
    @enabled = options.enabled or true

    lru_options = {}
    for key, value of options
      key = @normalizeKey(key)
      lru_options[key] = value

    @cache = new LRU(lru_options)

  cacheKey: (model_type, query) -> "#{_.result(model_type.prototype, 'url')}_#{JSON.stringify(query)}"

  set: (model_type, query, related_model_types, value) =>
    return @ unless @enabled
#    console.log 'SET', @cacheKey(model_type, query)
    model_types = [model_type].concat(related_model_types or [])
    @cache.set(@cacheKey(model_type, query), {model_types: model_types, value: value})
    return @

  get: (model_type, query) =>
    return null unless @enabled
#    console.log '******HIT', @cacheKey(model_type, query), @cache.get(@cacheKey(model_type, query))?.value if @cache.get(@cacheKey(model_type, query))?.value
    return @cache.get(@cacheKey(model_type, query))?.value

  reset: (model_types) =>
    (@cache.reset(); return @) unless model_types
    return @ unless @enabled
    model_types = [model_types] unless _.isArray(model_types)

    related_model_types = []
    for model_type in model_types
      for key, relation of model_type.schema().relations
        console.log key, relation unless relation
        related_model_types.push(relation.reverse_model_type)
        related_model_types.push(relation.join_table) if relation.join_table
    model_types = model_types.concat(related_model_types)

#    console.log 'clearing', @cache.keys().length, (m.name for m in model_types)
    # clear the full cache
    if arguments.length is 0
      @cache.reset()
      return @

    cleard = 0
    # Clear everything depending on the given model_type
    @cache.forEach (value, key, cache) ->
      for model_type in model_types
        (cleard = cleard+1; cache.del(key)) if model_type in value.model_types
#        console.log 'MISSS', key, model_type.name, (m.name for m in value.model_types) if model_type not in value.model_types

#    console.log 'c', cleard, @cache.keys().length
    return @

  normalizeKey: (key) -> inflection.camelize(key)

module.exports = cache = new QueryCache()

#cache.configure({enabled: true})
