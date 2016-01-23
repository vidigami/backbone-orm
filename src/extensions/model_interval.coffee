###
  backbone-orm.js 0.7.14
  Copyright (c) 2013-2016 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

_ = require 'underscore'

Queue = require '../lib/queue'
Utils = require '../lib/utils'
JSONUtils = require '../lib/json_utils'
DateUtils = require '../lib/date_utils'

INTERVAL_TYPES = ['milliseconds', 'seconds', 'minutes', 'hours', 'days', 'weeks', 'months', 'years']

module.exports = (model_type, query, iterator, callback) ->

  options = query.$interval or {}
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
    length_ms = DateUtils.durationAsMilliseconds((if _.isUndefined(options.length) then 1 else options.length), options.type)
    throw Error("length_ms is invalid: #{length_ms} for range: #{JSONUtils.stringify(range)}") unless length_ms

    query = _.omit(query, '$interval')
    query.$sort = [key]
    processed_count = 0
    iteration_info.index = 0

    runInterval = (current) ->
      return callback() if DateUtils.isAfter(current, range.end) # done

      # find the next entry
      query[key] = {$gte: current, $lte: iteration_info.last}
      model_type.findOne query, (err, model) ->
        return callback(err) if err
        return callback() unless model # done

        # skip to next
        next = model.get(key)
        iteration_info.index = Math.floor((next.getTime() - start_ms) / length_ms)

        current = new Date(range.start.getTime() + iteration_info.index * length_ms)
        iteration_info.start = current
        next = new Date(current.getTime() + length_ms)
        iteration_info.end = next

        query[key] = {$gte: current, $lt: next}
        iterator query, iteration_info, (err) ->
          return callback(err) if err
          runInterval(next)

    runInterval(range.start)
