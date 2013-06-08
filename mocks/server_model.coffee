util = require 'util'
_ = require 'underscore'
Backbone = require 'backbone'

MockCursor = require './cursor'

module.exports = class MockServerModel extends Backbone.Model
  @MODELS_JSON = []

  ###################################
  # Override Backbone.Model methods for the json array
  ###################################

  save: (attributes={}, options={}) ->
    @set(_.extend({id: _.uniqueId()}, attributes))
    MockServerModel.MODELS_JSON.push(@toJSON())
    options.success?(@)

  destroy: (options={}) ->
    id = @get('id')
    for index, json of MockServerModel.MODELS_JSON
      if json.id is id
        delete MockServerModel.MODELS_JSON[index]
        return options.success?(@)
     options.error?(@)

  ###################################
  # Collection Extensions
  ###################################
  @cursor: (query={}) -> return new MockCursor(query, {model_type: MockServerModel, json: MockServerModel.MODELS_JSON})

  @find: (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1
    @cursor(query).toModels(callback)

  ###################################
  # Convenience Functions
  ###################################
  @all: (callback) -> @cursor({}).toModels callback

  @count: (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1
    @cursor(query).count(callback)

  @destroy: (query, callback) ->
    # @initialize() unless @connection

    # [query, callback] = [{}, query] if arguments.length is 1
    # @connection.collection (err, collection) =>
    #   return callback(err) if err
    #   collection.remove @backbone_adapter.attributesToNative(query), callback
