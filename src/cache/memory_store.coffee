###
  backbone-orm.js 0.0.1
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js and Underscore.js.
###

_ = require 'underscore'
LRU = require 'lru-cache'
inflection = require 'inflection'

module.exports = class MemoryStore
  constructor: (options={}) ->
    normalized_options = {}
    for key, value of options
      if key is 'destroy'
        normalized_options.dispose = value
      else
        normalized_options[@_normalizeKey(key)] = value
    @cache = new LRU(normalized_options)

  set: (key, value, callback) =>
#    console.log 'set, ', key, value
    return callback?(null, value) or @ if value._orm_never_cache # skip cache
    @cache.set(key, value)
    callback?(null, value)
    return @

  get: (key, callback) =>
    value = @cache.get(key)
#    console.log 'get, ', key, value
    callback?(null, value)
    return value

  destroy: (key, callback) =>
#    console.log 'destroy, ', key
    @cache.del(key)
    callback?()
    return @

  reset: (callback) =>
    @cache.reset()
    callback?()
    return @

  _normalizeKey: (key) ->
    key = inflection.underscore(key)
    return key.toLowerCase() if key.indexOf('_') < 0
    return inflection.camelize(key)
