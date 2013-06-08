Queue = require 'queue-async'

DEFAULT_LIMIT = 1500
PARALLEL_COUNT = 100

module.exports = class BatchUtils
  @processModels: (model_type, callback, fn, limit=DEFAULT_LIMIT, parallel_count=PARALLEL_COUNT) ->
    runBatch = (query, callback) ->
      model_type.cursor(query).toModels (err, models) ->
        return callback(new Error("Failed to get models")) if err or !models
        return callback() unless models.length

        # batch operations on each
        queue = new Queue(parallel_count)
        do (model) -> queue.defer (callback) -> fn(model, callback) for model in models
        queue.await (err) ->
          return callback(err) if err
          query.$offset += query.$limit
          runBatch(query, callback)

    query = {
      $limit: limit
      $offset: 0
      $sort: [['id', 'asc']]
    }
    runBatch(query, callback)
