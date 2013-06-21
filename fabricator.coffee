util = require 'util'
_ = require 'underscore'
moment = require 'moment'
Queue = require 'queue-async'

Utils = require './lib/utils'
adapters = Utils.adapters

module.exports = class Fabricator

  @new: (model_type, count, attributes_info) ->
    results = []
    while(count-- > 0)
      attributes = {}
      (attributes[key] = if _.isFunction(value) then value() else value) for key, value of attributes_info
      results.push(new model_type(attributes))
    return results

  @create: (model_type, count, attributes_info, callback) ->
    models = Fabricator.new(model_type, count, attributes_info)
    queue = new Queue()
    for model in models
      do (model) -> queue.defer (callback) -> model.save {}, adapters.bbCallback(callback)
    queue.await (err) -> callback(err, models)

  # One forms
  # 1) Fabricator.value: a fixed value
  @value: (value) ->
    return undefined if arguments.length is 0
    return -> value

  # Two forms
  # 1) Fabricator.uniqueId: no prefix
  # 2) Fabricator.uniqueId(prefix): with prefix
  @uniqueId: (prefix) ->
    return _.uniqueId() if arguments.length is 0
    return -> _.uniqueId(prefix)
  @uniqueString: @uniqueId # alias

  # Two forms
  # 1) Fabricator.date: the current date
  # 1) Fabricator.date(step_ms): step in milliseconds from now
  # 1) Fabricator.date(start, step_ms): step in milliseconds from start
  @date: (start, step_ms) ->
    _normalize = (_date) -> _date.millisecond(0); return _date.toDate()

    # drop milliseconds for mysql DATETIME. TODO: determine whether this is necessary
    return _normalize(moment.utc()) if arguments.length is 0
    [start, step_ms] = [moment.utc(), start] if arguments.length is 1
    current_ms = start.valueOf()
    return ->
      current = new Date(current_ms)
      current_ms += step_ms
      return current
