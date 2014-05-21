Queue = require '../../lib/queue'

# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the models_json for the current run
module.exports = (options, callback) ->
  queue = new Queue(1)
  queue.defer (callback) -> require('./relational/self')(options, callback)
  queue.defer (callback) -> require('./relational/dsl')(options, callback)
  queue.defer (callback) -> require('./relational/has_many')(options, callback)
  queue.defer (callback) -> require('./relational/has_one')(options, callback)
  queue.defer (callback) -> require('./relational/many_to_many')(options, callback)
  queue.defer (callback) -> require('./relational/to_json')(options, callback)
  queue.defer (callback) -> require('./relational/join_table')(options, callback)
  queue.await callback
