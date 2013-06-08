_ = require 'underscore'
moment = require 'moment'

INTERVAL_TYPES = ['seconds', 'minutes', 'hours', 'days', 'weeks', 'months', 'years']

module.exports = class IntervalIterator
  constructor: (options) ->
    @[key] = value for key, value of options

    throw new Error("missing model_type") unless @model_type
    throw new Error("missing interval_type") unless @interval_type
    throw new Error("missing range_query") unless @range_query
    throw new Error("interval_type is not recognized: #{@interval_type}, #{_.contains(INTERVAL_TYPES, @interval_type)}") unless _.contains(INTERVAL_TYPES, @interval_type)

    # start
    start = @range_query.$gte if @range_query.$gte
    start = moment.utc().toDate() unless start
    @start_ms = start.getTime()

    # end
    end = @range_query.$lte if @range_query.$lte
    end = moment.utc().toDate() unless end
    @end_ms = end.getTime()

    # interval step
    @interval_length_ms = moment.duration((if _.isUndefined(@interval_length) then 1 else @interval_length), @interval_type).asMilliseconds()
    throw Error("interval_length_ms is invalid: #{@interval_length}") unless @interval_length_ms

  contains: (date) ->
    time_ms = if date.getTime then date.getTime() else date
    return time_ms >= @start_ms and time_ms <= @end_ms

  toIndex: (date) ->
    return -1 unless @contains(date)
    time_ms = if date.getTime then date.getTime() else date
    return Math.floor((time_ms - @start_ms) / @interval_length_ms)

  startIndex: -> return 0
  endIndex: ->
    return Math.floor((@end_ms - @start_ms) / @interval_length_ms)

  findStartCap: (query, callback) ->
    start = @range_query.$gte if @range_query.$gte
    start = moment.utc().toDate() unless start
    @model_type.findOneNearDate {key: @key, date: start, query: query, reverse: true}, callback

  findEndCap: (query, callback) ->
    end = @range_query.$lte if @range_query.$lte
    end = moment.utc().toDate() unless end
    @model_type.findOneNearDate {key: @key, date: end, query: query}, callback
