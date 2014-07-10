BackboneORM = window?.BackboneORM or require?('backbone-orm')
Queue = BackboneORM.Queue

# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the models_json for the current run
module.exports = (options, callback) ->
  queue = new Queue(1)
  queue.defer (callback) -> require('./iteration/each')(options, callback)
  queue.defer (callback) -> require('./iteration/interval')(options, callback)
  queue.defer (callback) -> require('./iteration/stream')(options, callback)
  queue.await callback
