util = require 'util'
_ = require 'underscore'

MemoryCursor = require './lib/memory_cursor'
Schema = require './lib/schema'
Utils = require './utils'
adapters = Utils.adapters

Cache = require './cache'

module.exports = class CacheSync
  CLASS_METHODS: ['initialize', 'cursor', 'find', 'count', 'all', 'destroy']

  constructor: (@sync) ->
    @model_type = @sync.model_type
    throw new Error("Missing url for model") unless @url = _.result(@model_type.prototype, 'url')

    # publish methods and sync on model
    # @model_type[fn] = _.bind(@[fn], @) for fn in @CLASS_METHODS

  initialize: -> @model_type._schema?.initialize()

  read: (model, options) ->
    if model.models
      # cached_models = Cache.getAll(@url)
    else
      if (cached_model = Cache.get(@url, model.attributes.id)) # use cached
        return options.success(cached_model.toJSON())
    @sync.read(model, options)

  create: (model, options) ->
    @sync.create model, adapters.bbCallback (err, json) =>
      Cache.add(@url, new @model_type(json)) # add to the cache

      return options.error(err) if err
      options.success(json)

  update: (model, options) ->
    if (cached_model = Cache.get(@url, model.attributes.id))
      cached_model.set(model.toJSON, options) if cached_model isnt model # update cache

    @sync.update model, adapters.bbCallback (err, json) =>
      return options.error(err) if err
      options.success(json)

  delete: (model, options) ->
    Cache.remove(@url, model.get('id')) # remove from the cache

    @sync.delete model, adapters.bbCallback (err, json) =>
      return options.error(err) if err
      options.success(json)

  # ###################################
  # # Collection Extensions
  # ###################################
  # cursor: (query={}) -> return new MemoryCursor(query, {model_type: @model_type})

  # find: (query, callback) ->
  #   [query, callback] = [{}, query] if arguments.length is 1
  #   @cursor(query).toModels(callback)

  # ###################################
  # # Convenience Functions
  # ###################################
  # all: (callback) -> @cursor({}).toModels callback

  # count: (query, callback) ->
  #   [query, callback] = [{}, query] if arguments.length is 1
  #   @cursor(query).count(callback)

  # destroy: (query, callback) ->
  #   [query, callback] = [{}, query] if arguments.length is 1
  #   if (keys = _.keys(query)).length
  #     for id, model of @store
  #       delete @store[id] if _.isEqual(_.pick(model.attributes, keys), query)
  #   else
  #     @store = {}
  #   return callback()

  ###################################
  # Cache Extension
  ###################################
  findCached: (ids, callback) -> return Cache.get(@url, ids)

# module.exports = (wrapped_sync) ->
#   sync = new CacheSync(wrapped_sync)
#   return (method, model, options={}) -> sync[method](model, options)
