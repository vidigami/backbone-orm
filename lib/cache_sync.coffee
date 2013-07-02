util = require 'util'
_ = require 'underscore'

CacheCursor = require './cache_cursor'
Schema = require './schema'
Utils = require './utils'

Cache = require './cache'

class CacheSync
  constructor: (@model_type, @wrapped_sync_fn) ->
    throw new Error('Missing model_name for model') unless @model_type.model_name

  initialize: ->
    return if @is_initialized; @is_initialized = true
    @wrapped_sync_fn('initialize')

  read: (model, options) ->
    if model.models
      # cached_models = Cache.findAll(@model_type.model_name)
    else
      if (cached_model = Cache.find(@model_type.model_name, model.attributes.id)) # use cached
        # console.log "CACHE: read found #{@model_type.model_name} id: #{cached_model.get('id')}"
        return options.success(cached_model.toJSON())
    @wrapped_sync_fn 'read', model, options

  create: (model, options) ->
    @wrapped_sync_fn 'create', model, Utils.bbCallback (err, json) =>
      Cache.findOrCreate(@model_type.model_name, @model_type, json) # add to the cache

      return options.error(err) if err
      options.success(json)

  update: (model, options) ->
    if (cached_model = Cache.find(@model_type.model_name, model.attributes.id))
      # console.log "CACHE: update found #{@model_type.model_name} id: #{cached_model.get('id')}"
      cached_model.set(model.toJSON, options) if cached_model isnt model # update cache

    @wrapped_sync_fn 'update', model, Utils.bbCallback (err, json) =>
      return options.error(err) if err
      options.success(json)

  delete: (model, options) ->
    Cache.remove(@model_type.model_name, model.get('id')) # remove from the cache

    @wrapped_sync_fn 'delete', model, Utils.bbCallback (err, json) =>
      return options.error(err) if err
      options.success(json)

  ###################################
  # Backbone ORM - Class Extensions
  ###################################
  cursor: (query={}) -> return new CacheCursor(query, _.pick(@, ['model_type', 'wrapped_sync_fn']))

  destroy: (query, callback) ->
    Cache.clear(@model_type.model_name) # TODO: optimize through selective cache clearing
    @wrapped_sync_fn 'destroy', query, callback

  cache: -> Cache

module.exports = (model_type, wrapped_sync_fn) ->
  sync = new CacheSync(model_type, wrapped_sync_fn)
  return (method, model, options={}) ->
    sync.initialize()
    return wrapped_sync_fn.apply(null, arguments) if method is 'createSync' # create a new sync
    return sync if method is 'sync'
    return wrapped_sync_fn('schema') if method is 'schema'
    if sync[method] then sync[method].apply(sync, Array::slice.call(arguments, 1)) else return undefined
