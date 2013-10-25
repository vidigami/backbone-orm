_ = require 'underscore'

module.exports = class MemoryStore
  constructor: (options={}) ->
    @cache = {}

  set: (key, value, callback) =>
    return callback?(null, value) or @ if value._orm_never_cache # skip cache
    @cache[key] = value
    callback?(null, value)
    return @

  get: (key, callback) =>
    value = @cache[key]
    callback?(null, value)
    return value

  destroy: (key, callback) =>
    delete @cache[key]
    callback?()
    return @

  reset: (callback) =>
    @cache = {}
    callback?()
    return @
