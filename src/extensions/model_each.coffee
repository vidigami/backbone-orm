_ = require 'underscore'
Queue = require '../queue'
Cursor = null

BATCH_DEFAULT_FETCH = 1000

module.exports = (model_type, query, iterator, callback) ->
  Cursor = require '../cursor' unless Cursor # module dependencies

  options = query.$each or {}
  method = if options.json then 'toJSON' else 'toModels'

  processed_count = 0
  parsed_query = Cursor.parseQuery(_.omit(query, '$each'))
  _.defaults(parsed_query.cursor, {$offset: 0, $sort: 'id'})

  model_limit = parsed_query.cursor.$limit or Infinity
  parsed_query.cursor.$limit = options.fetch or BATCH_DEFAULT_FETCH

  runBatch = (callback) ->
    cursor = model_type.cursor(parsed_query)
    cursor[method].call cursor, (err, models) ->
      return callback(new Error("Failed to get models. Error: #{err}")) if err or !models
      return callback(null, processed_count) unless models.length

      # each operations on each
      queue = new Queue(options.threads)
      for model in models
        break if (++processed_count >= model_limit)
        do (model) -> queue.defer (callback) -> iterator(model, callback)

      queue.await (err) ->
        return callback(err) if err
        return callback(null, processed_count) if (processed_count >= model_limit)
        return callback(null, processed_count) if models.length < parsed_query.cursor.$limit # we fetched less than the total
        parsed_query.cursor.$offset += parsed_query.cursor.$limit
        runBatch(callback)

  runBatch(callback)
