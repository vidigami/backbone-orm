inflection = require 'inflection'
LRU = require 'lru-cache'

module.exports = class LRUStore
  constructor: (options={}) ->
    if options.camelize
      store_options = {}
      (store_options[inflection.camelize(key, true)] = value) for key, value of options
    else
      store_options = options
    @cache = new LRU(store_options)

  set: (key, value, callback) =>
    @cache.set(key, value)
    callback(null, value)

  get: (key, callback) =>
    callback(null, @cache.get(key))

  reset: (callback) =>
    @cache.reset()
    callback()

  del: (key, callback) =>
    @cache.del(key)
    callback()
