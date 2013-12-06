###
  backbone-orm.js 0.5.4
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js, Underscore.js, Moment.js, and Inflection.js.
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
    return callback?(null, value) or @ if value._orm_never_cache # skip cache
    @cache.set(key, value)
    callback?(null, value)
    return @

  get: (key, callback) =>
    value = @cache.get(key)
    callback?(null, value)
    return value

  destroy: (key, callback) =>
    @cache.del(key)
    callback?()
    return @

  reset: (callback) =>
    @cache.reset()
    callback?()
    return @

  # @private
  _normalizeKey: (key) ->
    key = inflection.underscore(key)
    return key.toLowerCase() if key.indexOf('_') < 0
    return inflection.camelize(key)

  forEach: (callback) => @cache.forEach(callback)

