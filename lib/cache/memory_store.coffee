_ = require 'underscore'

module.exports = class MemoryStore
  constructor: (options={}) ->
    @cache = {}

  set: (key, value, callback) =>
    return callback(null, value) if value._orm_never_cache # skip cache
    @cache[key] = value
    callback?(null, value)
    return @

  get: (key, callback) =>
    value = @cache[key]
    callback?(null, value)
    return value

  reset: (callback) =>
    @cache = {}
    callback?()
    return @

  del: (key, callback) =>
    delete @cache[key]
    callback?()
    return @
