util = require 'util'
_ = require 'underscore'

Utils = require './utils'

MAX_CACHE_MS = 500 # TODO: determine the best amount

class Cache
  constructor: ->
    @store_by_url = {}

  find: (url, data) ->
    (return if _.isArray(data) then [] else null) unless model_store = @store_by_url[url] # no model store, nothing to find

    now = (new Date()).valueOf()
    return @_getOrInvalidateModel(model_store, data, now) unless _.isArray(data) # one

    # many
    results = []
    results.push(model) for item in data when (model = @_getOrInvalidateModel(model_store, item, now))
    return results

  findOrCreate: (url, data, model_type) ->
    (@store_by_url[url] = model_store = {}) unless model_store = @store_by_url[url]

    now = (new Date()).valueOf()
    unless _.isArray(data) # one
      return model if model = @_getOrInvalidateModel(Utils.dataId(data), now)
      return @_createModel(model_store, data, model_type, now)

    # many
    results = []
    for item in data
      if model = @_getOrInvalidateModel(Utils.dataId(item), now)
        results.push()
      else
        results.push(@_createModel(model_store, item, model_type, now))
    return results

  add: (url, models) ->
    (@store_by_url[url] = model_store = {}) unless model_store = @store_by_url[url]

    now = (new Date()).valueOf()
    return @_addModel(model_store, models, now) unless _.isArray(models) # one

    # many
    @_addModel(model_store, model, now) for model in models
    return @

  clear: (url, ids) ->
    (@store_by_url[url] = {}; return @) unless models
    if model_store = @store_by_url[url]
      if _.isArray(ids) # many
        delete model_store[id] for id in ids
      else # one
        delete model_store[id]
    return @

  _createModel: (model_store, data, model_type, now) ->
    data = {id: data} unless _.isObject(data)
    @_addModel(model_store, model = new model_type(data), now)
    return model

  _addModel: (model_store, model, now) ->
    throw new Error "Cannot store a model without an id: #{util.inspect(model.attributes)}" unless model.attributes.id
    model_store[model.attributes.id] = {model: model, last_used: now}
    return @

  _getOrInvalidateModel: (model_store, id, now) ->
    return null unless model_info = model_store[id] # not found

    # too old
    (delete model_store[id]; return null) if (now - model_info.last_used) > MAX_CACHE_MS

    # update timestamp and return
    model_info.last_used = now
    return model_info.model

# singleton
module.exports = new Cache()
