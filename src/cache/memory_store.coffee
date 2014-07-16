###
  backbone-orm.js 0.6.0
  Copyright (c) 2013-2014 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
###

_ = require 'underscore'
LRU = require 'lru-cache'

module.exports = class MemoryStore
  constructor: (options={}) ->
    normalized_options = {}
    for key, value of options
      if key is 'destroy' then (key = 'dispose') else if key is 'max_age' then (key = 'maxAge')
      normalized_options[key] = value
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
  del: @::destroy

  reset: (callback) =>
    @cache.reset()
    callback?()
    return @

  forEach: (callback) => @cache.forEach(callback)
