util = require 'util'
_ = require 'underscore'
inflection = require 'inflection'

MemoryCursor = require './lib/memory_cursor'
Schema = require './lib/schema'
Utils = require './lib/utils'

class MemorySync
  constructor: (@model_type) ->
    @store = {}

    # publish methods and sync on model
    @url = _.result(@model_type.prototype, 'url')
    @model_type.model_name = Utils.parseUrl(@url).model_name unless @model_type.model_name # model_name can be manually set
    throw new Error('Missing model_name for model') unless @model_type.model_name
    @model_type.prototype.urlRoot = "/#{inflection.underscore(@model_type.model_name)}" unless @url # add a default url
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
    if (keys = _.keys(query)).length
      for id, model_json of @store
        delete @store[id] if _.isEqual(_.pick(model_json, keys), query)
    else
      @store = {}
    return callback()

  schema: (key) -> @model_type._schema
  relation: (key) -> @model_type._schema.relation(key)


module.exports = (model_type, cache) ->
  sync = new MemorySync(model_type)

  sync_fn = (method, model, options={}) ->
    sync['initialize']()
    return module.exports.apply(null, Array::slice.call(arguments, 1)) if method is 'createSync' # create a new sync
    return sync if method is 'sync'
    sync[method].apply(sync, Array::slice.call(arguments, 1))

  require('./lib/model_extensions')(model_type, sync_fn) # mixin extensions
  return if cache then require('./lib/cache_sync')(model_type, sync_fn) else sync_fn