util = require 'util'
_ = require 'underscore'

MemoryCursor = require './memory_cursor'
Schema = require './schema'
Utils = require './utils'
adapters = Utils.adapters

Cache = require './cache'

class CacheSync
  constructor: (model_type, @sync) ->
    @model_type = model_type
    throw new Error("Missing url for model") unless @url = _.result(model_type.prototype, 'url')

    # publish methods and sync on model
    model_type._cache = @

  initialize: ->
    return if @is_initialized; @is_initialized = true
    @sync 'initialize', @model_type

  read: (model, options) ->
    if model.models
      # cached_models = Cache.findAll(@url)
    else
      if (cached_model = Cache.find(@url, model.attributes.id)) # use cached
        # console.log "CACHE: read found #{@model_type.model_name} id: #{cached_model.get('id')}"
        return options.success(cached_model.toJSON())
    @sync 'read', model, options

  create: (model, options) ->
    @sync 'create', model, adapters.bbCallback (err, json) =>
      Cache.findOrCreate(@url, json, @model_type) # add to the cache

      return options.error(err) if err
      options.success(json)

  update: (model, options) ->
    if (cached_model = Cache.find(@url, model.attributes.id))
      # console.log "CACHE: update found #{@model_type.model_name} id: #{cached_model.get('id')}"
      cached_model.set(model.toJSON, options) if cached_model isnt model # update cache

    @sync 'update', model, adapters.bbCallback (err, json) =>
      return options.error(err) if err
      options.success(json)

  delete: (model, options) ->
    Cache.remove(@url, model.get('id')) # remove from the cache

    @sync 'delete', model, adapters.bbCallback (err, json) =>
      return options.error(err) if err
      options.success(json)

  ###################################
  # Cache Extension
  ###################################
  updateCached: (model) -> Cache.update(@url, model)
  findCached: (data) -> return Cache.find(@url, data)
  findCachedOrCreate: (data, model_type) -> return Cache.findOrCreate(@url, data, model_type)

module.exports = (model_type, wrapped_sync) ->
  sync = new CacheSync(model_type, wrapped_sync)

  return (method, model, options={}) ->
    sync['initialize']()
    sync[method].apply(sync, Array::slice.call(arguments, 1))
