util = require 'util'
_ = require 'underscore'
Queue = require 'queue-async'

Cursor = require './cursor'

DEFAULT_LIMIT = 1500
DEFAULT_PARALLELISM = 1

module.exports = class BatchUtils
  @processModels: (model_type, query, options, callback, fn) ->
    [query, options, callback, fn] = [{}, {}, query, options] if arguments.length is 3
    [query, options, callback, fn] = [{}, query, options, callback] if arguments.length is 4

    processed_count = 0
    parsed_query = Cursor.parseQuery(query)
    parallelism = if options.hasOwnProperty('parallelism') then options.parallelism else DEFAULT_PARALLELISM
    method = options.method or 'toModels'

    runBatch = (batch_cursor, callback) ->
      cursor = model_type.cursor(batch_cursor)
      cursor[method].call cursor, (err, models) ->
        return callback(new Error("Failed to get models")) if err or !models
        return callback(null, processed_count) unless models.length

        # batch operations on each
        queue = new Queue(parallelism)
        for model in models
          do (model) -> queue.defer (callback) -> fn(model, callback)
          processed_count++
          break if parsed_query.cursor.$limit and (processed_count >= parsed_query.cursor.$limit)
        queue.await (err) ->
          return callback(err) if err
          return callback(null, processed_count) if parsed_query.cursor.$limit and (processed_count >= parsed_query.cursor.$limit)
          batch_cursor.$offset += batch_cursor.$limit
          runBatch(batch_cursor, callback)

    batch_cursor = _.extend({
      $limit: options.$limit or DEFAULT_LIMIT
      $offset: parsed_query.$offset or 0
      $sort: parsed_query.$sort or 'id' # TODO: generalize sort for different types of sync
    }, parsed_query.find) # add find parameters
    runBatch(batch_cursor, callback)


# EventEmitter = require('events').EventEmitter
# Queue = require 'queue-async'

# Query = require './query'

# module.exports = class BatchUtils
#   @processModels: (model_type, options={}, callback, per_model_fn) ->
#     event_emitter = new EventEmitter()

#     parallelism = options.parallelism or 1
#     total_processed = 0
#     is_done = false

#     query = {$offset: 0, $sort: [['id', 'asc']]}
#     (query[key] = value if key[0] is '$') for key, value of options
#     limit = query.$limit or -1 # limit is for total number of items
#     query.$limit = options.batch_size or Math.max(parallelism, 1) # batch size is per iteration

#     runBatch = (query, callback) ->

#       db_query = new Query(model_type, query)
#       db_query.toModels (err, models) ->
#         return callback(new Error("Failed to get models")) if err or !models
#         (is_done = true; return callback()) unless models.length

#         # batch operations on each
#         queue = new Queue(parallelism)

#         for model in models
#           (is_done = true; return callback()) if limit >= 0 and (total_processed >= limit) # done
#           total_processed++
#           do (model) -> queue.defer (callback) -> per_model_fn(model, callback)

#         queue.await (err) ->
#           return callback(err) if err
#           return callback(null, total_processed) if is_done
#           query.$offset += total_processed
#           runBatch(query, callback)

#     runBatch(query, callback)
#     return event_emitter