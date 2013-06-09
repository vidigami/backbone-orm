util = require 'util'
_ = require 'underscore'
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
      do (model) -> queue.defer (callback) -> models.save {}, adapters.bbCallback(callback)
    queue.await callback

  @idFn: (prefix) -> return -> _.uniqueId(prefix or '')
  @date: -> new Date()
  @dateString: -> Fabricator.date().toISOString()
