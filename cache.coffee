MAX_CACHE_MS = 500 # TODO: determine the best amount

class Cache
  constructor: ->
    @store_by_url = {}

  get: (url, ids) ->
    # many
    if _.isArray(ids)
      return [] unless models_store = @store_by_url[url]
      now = (new Date()).valueOf()

      results = []
      (results.push(model_info.model) if model = @_getOrClear(models_store, id, now)) for id in ids
      return results

    # one
    else
      return null unless models_store = @store_by_url[url]
      return @_getOrClear(models_store, id)

  add: (url, models) ->
    unless models_store = @store_by_url[url]
      @store_by_url[url] = model_store = {}

    # many
    now = (new Date()).valueOf()
    if _.isArray(models)
      model_store[model.get('id')] = {model: model, last_used: now} for model in models

    # one
    else
      model_store[model.get('id')] = {model: model, last_used: now}
    return @

  clear: (url, ids) ->
    if ids
      if models_store = @store_by_url[url]
        # many
        if _.isArray(ids)
          delete models_store[ids] for id in ids

        # one
        else
          delete models_store[ids]

    else
      @store_by_url[url] = {}
    return @

  _getOrClear: (models_store, id, now) ->
    now = (new Date()).valueOf() unless now
    return null unless model_info = model_store[id] # not found

    # too old
    (delete model_store[id]; return null) if (now - model_info.last_used) > MAX_CACHE_MS

    # update timestamp and return
    model_info.last_used = now
    return model_info.model

module.exports = new Cache()