util = require 'util'
_ = require 'underscore'

CacheCursor = require './cache_cursor'
Schema = require './schema'
Utils = require './utils'

Cache = require './cache'

DEFAULT_LIMIT = 1000
DEFAULT_PARALLELISM = 100

# @private
class CacheSync
  constructor: (@model_type, @wrapped_sync_fn) ->

  initialize: ->
    return if @is_initialized; @is_initialized = true
    @wrapped_sync_fn('initialize')
    throw new Error('Missing model_name for model') unless @model_type.model_name

  read: (model, options) ->
    if (cached_model = Cache.get(@model_type.model_name, model.id)) # use cached
      return options.success(cached_model.toJSON())
    @wrapped_sync_fn 'read', model, options

  create: (model, options) ->
    @wrapped_sync_fn 'create', model, Utils.bbCallback (err, json) =>
      return options.error(err) if err
      Utils.updateOrNew(json, @model_type)
      options.success(json)

  update: (model, options) ->
    @wrapped_sync_fn 'update', model, Utils.bbCallback (err, json) =>
      return options.error(err) if err
      Utils.updateOrNew(json, @model_type)
      options.success(json)

  delete: (model, options) ->
    Cache.del(@model_type.model_name, model.id) # remove from the cache
    @wrapped_sync_fn 'delete', model, Utils.bbCallback (err, json) =>
      return options.error(err) if err
      options.success(json)

  ###################################
  # Backbone ORM - Class Extensions
  ###################################
  resetSchema: (options, callback) ->
    Cache.reset(@model_type.model_name)
    @wrapped_sync_fn('resetSchema', options, callback)

  cursor: (query={}) -> return new CacheCursor(query, _.pick(@, ['model_type', 'wrapped_sync_fn']))

  destroy: (query, callback) ->
    # TODO: review for optimization
    @model_type.batch query, {$limit: DEFAULT_LIMIT, parallelism: DEFAULT_PARALLELISM}, callback, (model, callback) ->
      model.destroy Utils.bbCallback callback

  ###################################
  # Backbone Cache Sync - Custom Extensions
  ###################################
  connect: (url) ->
    Cache.clear(@model_type.model_name)
    @wrapped_sync_fn('connect')

  cache: -> Cache.getOrCreateModelCache(@model_type.model_name)

module.exports = (model_type, wrapped_sync_fn) ->
  sync = new CacheSync(model_type, wrapped_sync_fn)

  model_type::sync = sync_fn = (method, model, options={}) -> # save for access by model extensions
    sync.initialize()
    return wrapped_sync_fn.apply(null, arguments) if method is 'createSync' # create a new sync
    return sync if method is 'sync'
    return wrapped_sync_fn('schema') if method is 'schema'
    if sync[method] then sync[method].apply(sync, Array::slice.call(arguments, 1)) else return undefined

  return sync_fn