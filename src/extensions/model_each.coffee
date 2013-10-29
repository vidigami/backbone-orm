_ = require 'underscore'
Queue = require '../queue'
Cursor = null

BATCH_DEFAULT_LIMIT = 1000

module.exports = (model_type, query, iterator, callback) ->
  Cursor = require '../cursor' unless Cursor # module dependencies

  options = query.$each or {}
  threads = if options.hasOwnProperty('threads') then options.threads else 1
  method = if options.json then 'toJSON' else 'toModels'

  processed_count = 0
  parsed_query = Cursor.parseQuery(_.omit(query, '$each'))

  runBatch = (each_cursor, callback) ->
    cursor = model_type.cursor(each_cursor)
    cursor[method].call cursor, (err, models) ->
      return callback(new Error("Failed to get models. Error: #{err}")) if err or !models
      return callback(null, processed_count) unless models.length

      # each operations on each
      queue = new Queue(threads)
      for model in models
        do (model) -> queue.defer (callback) -> iterator(model, callback)
        processed_count++
        break if parsed_query.cursor.$limit and (processed_count >= parsed_query.cursor.$limit)
      queue.await (err) ->
        return callback(err) if err
        return callback(null, processed_count) if parsed_query.cursor.$limit and (processed_count >= parsed_query.cursor.$limit)
        return callback(null, processed_count) if models.length < each_cursor.$limit
        each_cursor.$offset += each_cursor.$limit
        runBatch(each_cursor, callback)

  each_cursor = _.extend({
    $limit: options.$limit or BATCH_DEFAULT_LIMIT
    $offset: parsed_query.cursor.$offset or 0
    $sort: parsed_query.cursor.$sort or 'id' # TODO: generalize sort for different types of sync
  }, parsed_query.find) # add find parameters
  runBatch(each_cursor, callback)
