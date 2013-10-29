_ = require 'underscore'
moment = require 'moment'
Queue = require '../queue'

INTERVAL_TYPES = ['milliseconds', 'seconds', 'minutes', 'hours', 'days', 'weeks', 'months', 'years']

module.exports = (model_type, query, iterator, callback) ->

  options = query.$interval or {}
  method = if options.json then 'toJSON' else 'toModels'
  throw new Error 'missing option: key' unless key = options.key
  throw new Error 'missing option: type' unless options.type
  throw new Error("type is not recognized: #{options.type}, #{_.contains(INTERVAL_TYPES, options.type)}") unless _.contains(INTERVAL_TYPES, options.type)
  iteration_info = _.clone(options)
  iteration_info.range = {} unless iteration_info.range
  range = iteration_info.range
  no_models = false

  queue = new Queue(1)

  # start
  queue.defer (callback) ->
    # find the first record
    unless start = (range.$gte or range.$gt)
      model_type.cursor(query).limit(1).sort(key).toModels (err, models) ->
        return callback(err) if err
        (no_models = true; return callback()) unless models.length
        range.start = iteration_info.first = models[0].get(key)
        callback()

    # find the closest record to the start
    else
      range.start = start
      model_type.findOneNearestDate start, {key: key, reverse: true}, query, (err, model) ->
        return callback(err) if err
        (no_models = true; return callback()) unless model
        iteration_info.first = model.get(key)
        callback()

  # end
  queue.defer (callback) ->
    return callback() if no_models

    # find the last record
    unless end = (range.$lte or range.$lt)
      model_type.cursor(query).limit(1).sort("-#{key}").toModels (err, models) ->
        return callback(err) if err
        (no_models = true; return callback()) unless models.length
        range.end = iteration_info.last = models[0].get(key)
        callback()

    # find the closest record to the end
    else
      range.end = end
      model_type.findOneNearestDate end, {key: key}, query, (err, model) ->
        return callback(err) if err
        (no_models = true; return callback()) unless model
        iteration_info.last = model.get(key)
        callback()

  # process
  queue.await (err) ->
    return callback(err) if err
    return callback() if no_models

    # interval length
    start_ms = range.start.getTime()
    length_ms = moment.duration((if _.isUndefined(options.length) then 1 else options.length), options.type).asMilliseconds()
    throw Error("length_ms is invalid: #{length_ms} for range: #{util.inspect(range)}") unless length_ms

    query = _.omit(query, '$interval')
    query.$sort = [key]
    processed_count = 0
    iteration_info.index = 0

    runInterval = (current) ->
      return callback() if current.isAfter(range.end) # done

      # find the next entry
      query[key] = {$gte: current.toDate(), $lte: iteration_info.last}
      model_type.findOne query, (err, model) ->
        return callback(err) if err
        return callback() unless model # done

        # skip to next
        next = model.get(key)
        iteration_info.index = Math.floor((next.getTime() - start_ms) / length_ms)

        current = moment.utc(range.start).add({milliseconds: iteration_info.index * length_ms})
        iteration_info.start = current.toDate()
        next = current.clone().add({milliseconds: length_ms})
        iteration_info.end = next.toDate()

        query[key] = {$gte: current.toDate(), $lt: next.toDate()}
        iterator query, iteration_info, (err) ->
          return callback(err) if err
          runInterval(next)

    runInterval(moment(range.start))
