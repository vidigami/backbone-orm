###
  backbone-orm.js 0.7.14
  Copyright (c) 2013-2016 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

_ = require 'underscore'

BackboneORM = require './core'
Queue = require './lib/queue'
MemoryCursor = require './cursor'
Schema = require './lib/schema'
Utils = require './lib/utils'
JSONUtils = require './lib/json_utils'

DESTROY_BATCH_LIMIT = 2000

CAPABILITIES = {embed: true, json: true, unique: true, manual_ids: true, dynamic: true, self_reference: true}

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
    @schema = new Schema(@model_type)
    @schema.type('id', 'Integer') unless @schema.field('id')?.type
    @store = @model_type.store or= []
    @id = 0
    @id_attribute = @model_type::idAttribute

  # @nodoc
  initialize: ->
    return if @is_initialized; @is_initialized = true
    @schema.initialize()
    @manual_id = true if @schema.field('id')?.manual
    @id_type = @schema.idType()

  ###################################
  # Classic Backbone Sync
  ###################################

  # @nodoc
  read: (model, options) ->
    if model.models
      options.success(JSONUtils.deepClone(model_json) for model_json in @store)
    else
      return options.error(new Error("Model not found with id: #{model.id}")) unless model_json = @get(model.id)
      options.success(JSONUtils.deepClone(model_json))

  # @nodoc
  create: (model, options) ->
    return options.error(new Error("Create should not be called for a manual id. Set an id before calling save. Model name: #{@model_type.model_name}. Model: #{JSONUtils.stringify(model.toJSON())}")) if @manual_id

    model.set(@id_attribute, if @id_type is 'String' then "#{++@id}" else ++@id)
    @store.splice(@insertIndexOf(model.id), 0, model_json = model.toJSON())
    options.success(JSONUtils.deepClone(model_json))

  # @nodoc
  update: (model, options) ->
    create = (index = @insertIndexOf(model.id)) >= @store.length or @store[index].id isnt model.id
    return options.error(new Error("Update cannot create a new model without manual option. Set an id before calling save. Model name: #{@model_type.model_name}. Model: #{JSONUtils.stringify(model.toJSON())}")) if not @manual_id and create

    model_json = model.toJSON()
    if create then @store.splice(index, 0, model_json) else @store[index] = model_json
    options.success(JSONUtils.deepClone(model_json))

  # @nodoc
  delete: (model, options) -> @deleteCB(model, (err) => if err then options.error(err) else options.success())

  # @nodoc
  deleteCB: (model, callback) =>
    return callback(new Error("Model not found. Type: #{@model_type.model_name}. Id: #{model.id}")) if (index = @indexOf(model.id)) < 0
    model_json = @store.splice(index, 1)
    Utils.patchRemove(@model_type, model, callback)

  ###################################
  # Backbone ORM - Class Extensions
  ###################################

  # @nodoc
  resetSchema: (options, callback) -> @destroy(callback)

  # @nodoc
  cursor: (query={}) -> return new MemoryCursor(query, _.pick(@, ['model_type', 'store']))

  # @nodoc
  destroy: (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1

    if JSONUtils.isEmptyObject(query)
      Utils.popEach @store, ((model_json, callback) => Utils.patchRemove(@model_type, model_json, callback)), callback
    else
      is_done = false
      cursor = @model_type.cursor(query).limit(DESTROY_BATCH_LIMIT)
      next = =>
        cursor.toJSON (err, models_json) =>
          return callback(err) if err
          return callback() if models_json.length is 0
          is_done = models_json.length < DESTROY_BATCH_LIMIT
          Utils.each models_json, @deleteCB, (err) -> if err or is_done then callback(err) else next()
      next()

  ###################################
  # Helpers
  ###################################
  get: (id) -> return if (index = _.sortedIndex(@store, {id}, @id_attribute)) >= @store.length or (model = @store[index]).id isnt id then null else model
  indexOf: (id) -> return if (index = _.sortedIndex(@store, {id}, @id_attribute)) >= @store.length or @store[index].id isnt id then -1 else index
  insertIndexOf: (id) -> return _.sortedIndex(@store, {id}, @id_attribute)

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
