util = require 'util'
_ = require 'underscore'

MemoryCursor = require './lib/memory_cursor'
Schema = require './lib/schema'
Utils = require './utils'

class MemoryBackboneSync
  constructor: (@model_type) ->
    throw new Error("Missing url for model") unless url = _.result(@model_type.prototype, 'url')
    @model_type.model_name = Utils.urlToModelName(url)

    @store = {}

    # publish methods and sync on model
    @model_type._sync = @
    @model_type._schema = new Schema(@model_type)

  initialize: ->
    return if @is_initialized; @is_initialized = true
    @model_type._schema.initialize()

  read: (model, options) ->
    options.success(if model.models then (json for id, json of @store) else @store[model.attributes.id])

  create: (model, options) ->
    model.attributes.id = Utils.guid()
    model_json = @store[model.attributes.id] = model.toJSON()
    options.success(model_json)

  update: (model, options) ->
    return options.error(new Error('Model not found')) unless model_json = @store[model.attributes.id]
    _.extend(model_json, model.toJSON())
    options.success(model_json)

  delete: (model, options) ->
    return options.error(new Error('Model not found')) unless model_json = @store[model.attributes.id]
    delete @store[model.attributes.id]
    options.success(model_json)

  ###################################
  # Backbone ORM - Class Extensions
  ###################################
  cursor: (query={}) -> return new MemoryCursor(query, {model_type: @model_type})

  destroy: (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1
    if (keys = _.keys(query)).length
      for id, model of @store
        delete @store[id] if _.isEqual(_.pick(model.attributes, keys), query)
    else
      @store = {}
    return callback()


module.exports = (model_type, cache) ->
  sync = new MemoryBackboneSync(model_type)

  sync_fn = (method, model, options={}) ->
    sync['initialize']()
    sync[method](model, options)

  require('./lib/model_extensions')(model_type, sync_fn)

  if cache
    return require('./cache_sync')(model_type, sync_fn)
  else
    return sync_fn