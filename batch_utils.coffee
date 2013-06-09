util = require 'util'
_ = require 'underscore'
Queue = require 'queue-async'

Cursor = require './cursor'

DEFAULT_LIMIT = 1500
DEFAULT_PARALLELISM = 1

module.exports = class BatchUtils
  @processModels: (model_type, query, options, callback, fn) ->
    if arguments.length is 3
      [model_type, query, options, callback, fn] = [model_type, {}, {}, query, options]
    else if arguments.length is 4
      [model_type, query, options, callback, fn] = [model_type, {}, query, options, callback]

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
      $sort: parsed_query.$sort or [['id', 'asc']] # TODO: generalize sort for different types of sync
    }, parsed_query.find) # add find parameters
    runBatch(batch_cursor, callback)
