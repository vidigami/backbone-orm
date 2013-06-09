util = require 'util'
EventEmitter = require('events').EventEmitter
Queue = require 'queue-async'

DEFAULT_LIMIT = 1500
PARALLEL_COUNT = 10

module.exports = class BatchUtils
  @processModels: (model_type, callback, fn, limit=DEFAULT_LIMIT, parallel_count=PARALLEL_COUNT) ->
    event_emitter = new EventEmitter()

    runBatch = (cursor, callback) ->
      model_type.cursor(cursor).toModels (err, models) ->
        return callback(new Error("Failed to get models")) if err or !models
        return callback() unless models.length
        event_emitter.emit 'progress', "Start batch length: #{models.length}"

        # batch operations on each
        queue = new Queue(parallel_count)
        for model in models
          do (model) -> queue.defer (callback) -> fn(model, callback)
        queue.await (err) ->
          return callback(err) if err
          cursor.$offset += cursor.$limit
          runBatch(cursor, callback)

    cursor = {
      $limit: DEFAULT_LIMIT
      $offset: 0
      $sort: [['id', 'asc']]
    }
    runBatch(cursor, callback)
    return event_emitter

# Queue = require 'queue-async'

# DEFAULT_LIMIT = 1500
# PARALLEL_COUNT = 100

# module.exports = class BatchUtils
#   @processModels: (model_type, callback, fn, limit=DEFAULT_LIMIT, parallel_count=PARALLEL_COUNT) ->
#     runBatch = (cursor, callback) ->
#       model_type.cursor(cursor).toModels (err, models) ->
#         return callback(new Error("Failed to get models")) if err or !models
#         return callback() unless models.length

#         # batch operations on each
#         queue = new Queue(parallel_count)
#         for model in models
#           do (model) -> queue.defer (callback) -> fn(model, callback)
#         queue.await (err) ->
#           return callback(err) if err
#           cursor.$offset += cursor.$limit
#           runBatch(cursor, callback)

#     cursor = {
#       $limit: limit
#       $offset: 0
#       $sort: [['id', 'asc']]
#     }
#     runBatch(cursor, callback)
