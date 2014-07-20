###
<<<<<<< HEAD
  backbone-orm.js 0.5.18
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
=======
  backbone-orm.js 0.6.0
  Copyright (c) 2013-2014 Vidigami
>>>>>>> 40bc5032387d4231b69d247c29e721b4dfccc8d3
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
###

_ = require 'underscore'
LRU = require 'lru-cache'

module.exports = class MemoryStore
  constructor: (options={}) ->
    (options = _.omit(options, 'max_age'))['maxAge'] = max_age if max_age = options.max_age
    @cache = new LRU(options)

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
