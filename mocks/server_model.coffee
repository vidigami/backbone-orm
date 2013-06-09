util = require 'util'
_ = require 'underscore'
Backbone = require 'backbone'

MockCursor = require './cursor'

module.exports = class MockServerModel extends Backbone.Model
  @MODELS = []

  ###################################
  # Override Backbone.Model methods for the json array
  ###################################

  save: (attributes={}, options={}) ->
    @set(attributes)
    @set({id: id = _.uniqueId()}) unless id = @get('id')
    if existing_model = _.find(MockServerModel.MODELS, (model) => model.get('id') is id)
      existing_model.set(@attributes)
    else
      MockServerModel.MODELS.push(@clone())

    options.success?(@)

  destroy: (options={}) ->
    id = @get('id')
    for index, model of MockServerModel.MODELS
      if model.get('id') is id
        delete MockServerModel.MODELS[index]
        return options.success?(@)
     options.error?(@)

  ###################################
  # Collection Extensions
  ###################################
  @cursor: (query={}) -> return new MockCursor(query, {model_type: MockServerModel, json: _.map(MockServerModel.MODELS, (model) -> model.toJSON())})

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
    [query, callback] = [{}, query] if arguments.length is 1
    unless (keys = _.keys(query)).length # all
      console.log "DESTROY ALL"
      MockServerModel.MODELS = []
      return callback()

    # find them
    console.log "FInd: #{util.inspect(query)}"
    @cursor(query).toJSON (err, json) ->
      return callback(err) if err
      json_find = _.map(json, (item) -> _.pick(item, keys))
      models_find = _.map(MockServerModel.MODELS, (model) -> _.pick(model.toJSON(), keys))
      for index, value of models_find
        delete MockServerModel.MODELS[index] if !!_.find(json_find, (item) -> _.isEqual(item, value))
      callback()
