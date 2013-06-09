util = require 'util'
_ = require 'underscore'
moment = require 'moment'
Queue = require 'queue-async'

Helpers = require './lib/test_helpers'
adapters = Helpers.adapters

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

  @uniqueId: (prefix) -> return -> _.uniqueId(prefix or '')
  @date: -> date = moment.utc(); date.millisecond(0); return date.toDate() # drop milliseconds for mysql DATETIME. TODO: determine whether this is necessary
  @dateString: -> Fabricator.date().toISOString()
