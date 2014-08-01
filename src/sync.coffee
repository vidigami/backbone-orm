###
  backbone-orm.js 0.6.1
  Copyright (c) 2013-2014 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

_ = require 'underscore'
Backbone = require 'backbone'

BackboneORM = require './core'
Queue = require './lib/queue'
MemoryCursor = require './cursor'
Schema = require './lib/schema'
Utils = require './lib/utils'
JSONUtils = require './lib/json_utils'

DESTROY_BATCH_LIMIT = 1000

CAPABILITIES = {embed: true, json: true, unique: false, self_reference: true}

# Backbone Sync for in-memory models.
#
# @example How to configure using a model name
#   class Thing extends Backbone.Model
#     model_name: 'Thing'
#     sync: require 'backbone-orm'.sync(Thing)
#
# @example How to configure using a url
#   class Thing extends Backbone.Model
#     url: '/things'
#     sync: require 'backbone-orm'.sync(Thing)
#
class MemorySync
  # @nodoc
  constructor: (@model_type) ->
    @model_type.model_name = Utils.findOrGenerateModelName(@model_type)
    @schema = new Schema(@model_type, {id: {type: 'Integer'}})

    @store = @model_type.store or= {}
    @id = 0

  # @nodoc
  initialize: ->
    return if @is_initialized; @is_initialized = true
    @schema.initialize()

  ###################################
  # Classic Backbone Sync
  ###################################

  # @nodoc
  read: (model, options) ->
    if model.models
      options.success(JSONUtils.deepClone(model_json) for id, model_json of @store)
    else
      return options.error(new Error("Model not found with id: #{model.id}")) if _.isUndefined(@store[model.id])
      options.success(JSONUtils.deepClone(@store[model.id]))

  # @nodoc
  create: (model, options) ->
    (attributes = {})[@model_type::idAttribute] = ++@id
    model.set(attributes)
    model_json = @store[model.id] = model.toJSON()
    options.success(JSONUtils.deepClone(model_json))

  # @nodoc
  update: (model, options) ->
    @store[model.id] = model_json = model.toJSON()
    options.success(JSONUtils.deepClone(model_json))

  # @nodoc
  delete: (model, options) ->
    return options.error(new Error('Model not found')) unless @store[model.id]
    delete @store[model.id]
    options.success()

  ###################################
  # Backbone ORM - Class Extensions
  ###################################

  # @nodoc
  resetSchema: (options, callback) -> @destroy({}, callback)

  # @nodoc
  cursor: (query={}) -> return new MemoryCursor(query, _.pick(@, ['model_type', 'store']))

  # @nodoc
  destroy: (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1

    @model_type.each _.extend({$each: {limit: DESTROY_BATCH_LIMIT, json: true}}, query),
      ((model_json, callback) =>
        Utils.patchRemoveByJSON @model_type, model_json, (err) =>
          delete @store[model_json[@model_type::idAttribute]] unless err
          callback(err)
      ), callback

module.exports = (type) ->
  if Utils.isCollection(new type()) # collection
    model_type = Utils.configureCollectionModelType(type, module.exports)
    return type::sync = model_type::sync

  sync = new MemorySync(type)
  type::sync = sync_fn = (method, model, options={}) -> # save for access by model extensions
    sync.initialize()
    return module.exports.apply(null, Array::slice.call(arguments, 1)) if method is 'createSync' # create a new sync
    return sync if method is 'sync'
    return false if method is 'isRemote'
    return sync.schema if method is 'schema'
    return undefined if method is 'tableName'
    return if sync[method] then sync[method].apply(sync, Array::slice.call(arguments, 1)) else undefined

  Utils.configureModelType(type)
  return BackboneORM.model_cache.configureSync(type, sync_fn)

module.exports.Sync = MemorySync
module.exports.Cursor = MemoryCursor
module.exports.capabilities = (url) -> CAPABILITIES
