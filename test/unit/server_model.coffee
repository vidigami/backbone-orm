testGenerator = require '../../lib/test_generators/server_model'

_ = require 'underscore'
MockServerModel = require '../../mocks/server_model'
Fabricator = require '../../fabricator'

testGenerator {
  model_type: MockServerModel
  route: 'mock_models'
  beforeEach: (callback) ->
    MockServerModel.MODELS = Fabricator.new(MockServerModel, 10, {
      id: Fabricator.uniqueId('id_')
      name: Fabricator.uniqueId('name_')
      created_at: Fabricator.dateString
      updated_at: Fabricator.dateString
    })
    callback(null, _.map(MockServerModel.MODELS, (model) -> model.toJSON()))
}