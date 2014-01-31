Queue = require '../../lib/queue'

# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the models_json for the current run
module.exports = (options, callback) ->
  queue = new Queue(1)
  # queue.defer (callback) -> require('./flat/sync')(options, callback)
  # queue.defer (callback) -> require('./flat/convenience')(options, callback)
  # queue.defer (callback) -> require('./flat/cursor')(options, callback)
  # queue.defer (callback) -> require('./flat/find')(options, callback)
  queue.defer (callback) -> require('./flat/page')(options, callback)
  # queue.defer (callback) -> require('./flat/sort')(options, callback)
  queue.await callback
