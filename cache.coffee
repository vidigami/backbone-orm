util = require 'util'
_ = require 'underscore'

MAX_CACHE_MS = 500 # TODO: determine the best amount

class Cache
  constructor: ->
    @store_by_url = {}

  get: (url, ids) ->
    unless model_store = @store_by_url[url] # no model store
      return if _.isArray(ids) then [] else null

    return @_getOrClearById(model_store, id) unless _.isArray(ids) # one

    # many
    now = (new Date()).valueOf()
    results = []
    results.push(model_info.model) for id in ids when (model = @_getOrClearById(model_store, id, now))
    return results

  add: (url, models) ->
    (@store_by_url[url] = model_store = {}) unless model_store = @store_by_url[url]

    return @_addModel(model_store, models) unless _.isArray(models) # one

    # many
    now = (new Date()).valueOf()
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

  _addModel: (model_store, model, now) ->
    throw new Error "Cannot store a model without an id" unless model.attributes.id
    model_store[model.attributes.id] = {model: model, last_used: now}
    return @

  _getOrClearById: (model_store, id, now) ->
    now = (new Date()).valueOf() unless now
    return null unless model_info = model_store[id] # not found

    # too old
    (delete model_store[id]; return null) if (now - model_info.last_used) > MAX_CACHE_MS

    # update timestamp and return
    model_info.last_used = now
    return model_info.model

# singleton
module.exports = new Cache()
