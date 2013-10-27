Queue = require '../../src/queue'
_ = require 'underscore'

# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the models_json for the current run
module.exports = (options, callback) ->
  return callback() unless options.query_cache
  queue = new Queue(1)
  queue.defer (callback) -> require('./query_cache/cache')(options, callback)
  queue.defer (callback) ->
    try
      RedisStore = require('store-redis')
      options.query_cache_options = {store: new RedisStore({url: 'redis://localhost:6379'})}
      require('./query_cache/cache')(options, callback)
    catch e
      console.error('Redis not installed, skipping')
      callback()
  queue.await callback
