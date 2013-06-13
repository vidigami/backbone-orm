_ = require 'underscore'

MemoryCursor = require './lib/memory_cursor'
relation_manager = require './lib/relation_manager'
SchemaParser = require './lib/parsers/schema'
RelationParser = require './lib/parsers/relation'

Cache = require './cache'

S4 = -> return (((1+Math.random())*0x10000)|0).toString(16).substring(1)
guid = -> return (S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4()+S4())

CLASS_METHODS = [
  'initialize'
  'cursor', 'find'
  'count', 'all', 'destroy'
]

class MemoryBackboneSync
  constructor: (@model_type) ->
    @store = {}

    # publish methods and sync on model
    @model_type[fn] = _.bind(@[fn], @) for fn in CLASS_METHODS
    # Cache.initialize(@model_type, @)
    @model_type._sync = @

    @schema_info = SchemaParser.parse(_.result(@model_type, 'schema') or {})
    @relations = RelationParser.parse(@model_type, @schema_info.raw_relations)

  initialize: -> @model_type::get = relation_manager(@model_type, @relations)

  read: (model, options) ->
    options.success?(if model.models then (model.attributes for id, model of @store) else @store[model.attributes.id].attributes)

  create: (model, options) ->
    model.attributes.id = guid()
    @store[model.attributes.id = guid()] = model.clone()
    options.success?(model.attributes)

  update: (model, options) ->
    return options.error(new Error('Model not found')) unless store_model = @store[model.attributes.id]
    _.extend(store_model.attributes, model.attributes)
    options.success?(store_model.attributes)

  delete: (model, options) ->
    return options.error(new Error('Model not found')) unless store_model = @store[model.attributes.id]
    delete @store[model.attributes.id]
    options.success?(store_model.attributes)

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