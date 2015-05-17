_ = require 'underscore'
Queue = require './queue'

# Fabricator to generate test data.
#
module.exports = class Fabricator

  # Create new models without saving them.
  #
  # @example
  #   Fabricator.create Thing, 200, {name: Fabricator.uniqueId('thing_'), created_at: Fabricator.date}, (err, models) -> # do something
  #
  @new: (model_type, count, attributes_info) ->
    results = []
    while(count-- > 0)
      attributes = {}
      (attributes[key] = if _.isFunction(value) then value() else value) for key, value of attributes_info
      results.push(new model_type(attributes))
    return results

  # Create new models and save them.
  #
  @create: (model_type, count, attributes_info, callback) ->
    models = Fabricator.new(model_type, count, attributes_info)
    queue = new Queue()
    for model in models then do (model) -> queue.defer (callback) -> model.save callback
    queue.await (err) -> callback(err, models)

  # Return the same fixed value for each fabricated model
  #
  @value: (value) ->
    return undefined if arguments.length is 0
    return -> value

  # Return the same fixed value for each fabricated model
  #
  @increment: (value) ->
    return undefined if arguments.length is 0
    return -> value++

  # Return a unique string value for each fabricated model
  #
  # @overload uniqueId()
  #   Creates a unique id without a prefix
  #
  # @overload uniqueId(prefix)
  #   Creates a unique id with a prefix
  #
  @uniqueId: (prefix) ->
    return _.uniqueId() if arguments.length is 0
    return -> _.uniqueId(prefix)

  # Alias for uniqueId
  #
  @uniqueString: @uniqueId

  # Return a date for each fabricated model
  #
  # @overload date()
  #   The current date/time
  #
  # @overload date(step_ms)
  #   Creates a new date/time for each call in fixed milliseconds from the date/time at the first call
  #
  # @overload date(start, step_ms)
  #   Creates a new date/time for each call in fixed milliseconds from a specified date/time
  @date: (start, step_ms) ->
    now = new Date()
    return now if arguments.length is 0

    [start, step_ms] = [now, start] if arguments.length is 1
    current_ms = start.getTime()
    return ->
      current = new Date(current_ms)
      current_ms += step_ms
      return current
