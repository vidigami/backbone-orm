Queue = require '../../lib/queue'

# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the models_json for the current run
module.exports = (options, callback) ->
  queue = new Queue(1)
  queue.defer (callback) -> require('./query_cache/cache')(options, callback)
  queue.defer (callback) -> require('./all_cache')(options, callback)
  queue.defer (callback) -> require('./all_collection')(options, callback)
  queue.defer (callback) -> require('./all_conventions')(options, callback)
  queue.defer (callback) -> require('./all_flat')(options, callback)
  queue.defer (callback) -> require('./all_migrations')(options, callback)
  queue.defer (callback) -> require('./all_relational')(options, callback)
  queue.await callback
