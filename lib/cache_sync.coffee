util = require 'util'
_ = require 'underscore'

MemoryCursor = require './memory_cursor'
Schema = require './schema'
Utils = require './utils'

Cache = require './cache'

class CacheSync
  constructor: (@model_type, @sync) ->
    @model_type.model_name

    # publish methods and sync on model
    @url = @sync.url
    throw new Error('Missing model_name for model') unless @model_type.model_name = @sync.model_name
    @model_type._cache = @

  initialize: ->
    return if @is_initialized; @is_initialized = true
    @sync 'initialize', @model_type

  read: (model, options) ->
    if model.models
      # cached_models = Cache.findAll(@model_name)
    else
      if (cached_model = Cache.find(@model_name, model.attributes.id)) # use cached
        # console.log "CACHE: read found #{@model_type.model_name} id: #{cached_model.get('id')}"
        return options.success(cached_model.toJSON())
    @sync 'read', model, options

  create: (model, options) ->
    @sync 'create', model, Utils.bbCallback (err, json) =>
      Cache.findOrCreate(@model_name, @model_type, json) # add to the cache

      return options.error(err) if err
      options.success(json)

  update: (model, options) ->
    if (cached_model = Cache.find(@model_name, model.attributes.id))
      # console.log "CACHE: update found #{@model_type.model_name} id: #{cached_model.get('id')}"
      cached_model.set(model.toJSON, options) if cached_model isnt model # update cache

    @sync 'update', model, Utils.bbCallback (err, json) =>
      return options.error(err) if err
      options.success(json)

  delete: (model, options) ->
    Cache.remove(@model_name, model.get('id')) # remove from the cache

    @sync 'delete', model, Utils.bbCallback (err, json) =>
      return options.error(err) if err
      options.success(json)

  ###################################
  # Cache Extension
  ###################################
  findOrCreate: (data) -> return Cache.findOrCreate(@model_name, @model_type, data)
  cacheUpdate: (data) -> Cache.update(@model_name, data)

module.exports = (model_type, wrapped_sync) ->
  sync = new CacheSync(model_type, wrapped_sync)

  return (method, model, options={}) ->
    sync['initialize']()
    sync[method].apply(sync, Array::slice.call(arguments, 1))
