util = require 'util'
_ = require 'underscore'

MemoryCursor = require './lib/memory_cursor'
Schema = require './lib/schema'
Utils = require './utils'

Cache = require './cache'

CLASS_METHODS = [
  'initialize'
  'cursor', 'find'
  'count', 'all', 'destroy'
]

class MemoryBackboneSync
  constructor: (@model_type) ->
    throw new Error("Missing url for model") unless url = _.result(@model_type.prototype, 'url')
    @model_type.model_name = Utils.urlToModelName(url)

    @store = {}

    # publish methods and sync on model
    @model_type[fn] = _.bind(@[fn], @) for fn in CLASS_METHODS
    # Cache.initialize(@model_type, @) # use composition instead
    @model_type._sync = @
    @model_type._schema = new Schema(@model_type)

  initialize: -> @model_type._schema?.initialize()

  read: (model, options) ->
    options.success?(if model.models then (json for id, json of @store) else @store[model.attributes.id])

  create: (model, options) ->
    model.attributes.id = Utils.guid()
    model_json = @store[model.attributes.id] = model.toJSON()
    options.success?(model_json)

  update: (model, options) ->
    return options.error(new Error('Model not found')) unless model_json = @store[model.attributes.id]
    _.extend(model_json, model.toJSON())
    options.success?(model_json)

  delete: (model, options) ->
    return options.error(new Error('Model not found')) unless model_json = @store[model.attributes.id]
    delete @store[model.attributes.id]
    options.success?(model_json)

  ###################################
  # Collection Extensions
  ###################################
  cursor: (query={}) -> return new MemoryCursor(query, {model_type: @model_type})

  find: (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1
    @cursor(query).toModels(callback)

  ###################################
  # Convenience Functions
  ###################################
  all: (callback) -> @cursor({}).toModels callback

  count: (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1
    @cursor(query).count(callback)

  destroy: (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1
    if (keys = _.keys(query)).length
      for id, model of @store
        delete @store[id] if _.isEqual(_.pick(model.attributes, keys), query)
    else
      @store = {}
    return callback()

# options
#   model_type - the model that will be used to add query functions to
module.exports = (model_type) ->
  sync = new MemoryBackboneSync(model_type)
  return (method, model, options={}) -> sync[method](model, options)