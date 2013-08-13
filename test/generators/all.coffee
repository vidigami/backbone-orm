Queue = require 'queue-async'

# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the models_json for the current run
module.exports = (options, callback) ->
  queue = new Queue(1)
  queue.defer (callback) -> require('./all_flat')(options, callback)
  queue.defer (callback) -> require('./all_relational')(options, callback)
  queue.defer (callback) -> require('./all_cache')(options, callback)
  queue.defer (callback) -> require('./conventions/one')(options, callback)
  queue.defer (callback) -> require('./conventions/many')(options, callback)
  queue.defer (callback) -> require('./collection/sync')(options, callback)
  queue.await callback
