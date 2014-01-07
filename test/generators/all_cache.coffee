Queue = require '../../lib/queue'

# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the models_json for the current run
module.exports = (options, callback) ->
  queue = new Queue(1)
  # queue.defer (callback) -> require('./cache/options')(options, callback)
  # queue.defer (callback) -> require('./cache/query')(options, callback)
  queue.await callback
