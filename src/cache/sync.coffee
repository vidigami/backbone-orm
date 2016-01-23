###
  backbone-orm.js 0.7.14
  Copyright (c) 2013-2016 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

_ = require 'underscore'

CacheCursor = require './cursor'
Schema = require '../lib/schema'
Utils = require '../lib/utils'
bbCallback = Utils.bbCallback

DESTROY_BATCH_LIMIT = 1000
DESTROY_THREADS = 100

# @nodoc
class CacheSync
  constructor: (@model_type, @wrapped_sync_fn) ->

  initialize: ->
    return if @is_initialized; @is_initialized = true
    @wrapped_sync_fn('initialize')
    throw new Error('Missing model_name for model') unless @model_type.model_name

  read: (model, options) ->
    return options.success(cached_model.toJSON()) if not options.force and (cached_model = @model_type.cache.get(model.id)) # use cached
    @wrapped_sync_fn 'read', model, options

  create: (model, options) ->
    @wrapped_sync_fn 'create', model, {
      success: (json) =>
        (attributes = {})[@model_type::idAttribute] = json[@model_type::idAttribute]
        model.set(attributes)
        if cache_model = @model_type.cache.get(model.id)
          Utils.updateModel(cache_model, model) if cache_model isnt model
        else
          @model_type.cache.set(model.id, model)
        options.success(json)
      error: (resp) => options.error?(resp)
    }

  update: (model, options) ->
    @wrapped_sync_fn 'update', model, {
      success: (json) =>
        if cache_model = @model_type.cache.get(model.id)
          Utils.updateModel(cache_model, model) if cache_model isnt model
        else
          @model_type.cache.set(model.id, model)
        options.success(json)
      error: (resp) => options.error?(resp)
    }

  delete: (model, options) ->
    @model_type.cache.destroy(model.id) # remove from the cache
    @wrapped_sync_fn 'delete', model, options

  ###################################
  # Backbone ORM - Class Extensions
  ###################################
  resetSchema: (options, callback) ->
    @model_type.cache.reset (err) =>
      return callback(err) if err
      @wrapped_sync_fn('resetSchema', options, callback)

  cursor: (query={}) -> return new CacheCursor(query, _.pick(@, ['model_type', 'wrapped_sync_fn']))

  destroy: (query, callback) ->
    # TODO: review for optimization
    @model_type.each _.extend({$each: {limit: DESTROY_BATCH_LIMIT, threads: DESTROY_THREADS}}, query), ((model, callback) => model.destroy callback), callback

  ###################################
  # Backbone Cache Sync - Custom Extensions
  ###################################
  connect: (url) ->
    @model_type.cache.reset()
    @wrapped_sync_fn('connect')

module.exports = (model_type, wrapped_sync_fn) ->
  sync = new CacheSync(model_type, wrapped_sync_fn)

  model_type::sync = sync_fn = (method, model, options={}) -> # save for access by model extensions
    sync.initialize()
    return wrapped_sync_fn.apply(null, arguments) if method is 'createSync' # create a new sync
    return sync if method is 'sync'
    return sync[method].apply(sync, Array::slice.call(arguments, 1)) if sync[method]
    return wrapped_sync_fn.apply(wrapped_sync_fn, Array::slice.call(arguments))

  return sync_fn
