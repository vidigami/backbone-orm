util = require 'util'
_ = require 'underscore'
Backbone = require 'backbone'

MockCursor = require './cursor'

module.exports = class MockServerModel extends Backbone.Model
  @MODELS_JSON = []

  @find: (query, callback) ->
    id = if _.isObject(query) then query.id else query
    json = _.find(MockServerModel.MODELS_JSON, (test) => test.id is id)
    callback(null, if json then new MockServerModel(json) else null)

  @cursor: (query) ->
    return new MockCursor(query, MockServerModel.MODELS_JSON)

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
