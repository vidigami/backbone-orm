_ = require 'underscore'
Queue = require 'queue-async'

JSONUtils = require '../../json_utils'
MockServerModel = require '../../mocks/server_model'
Fabricator = require '../../fabricator'

test_parameters =
  model_type: MockServerModel
  route: 'mock_models'
  beforeEach: (callback) ->
    queue = new Queue(1)
    queue.defer (callback) -> MockServerModel.destroy {}, callback
    queue.defer (callback) -> Fabricator.create(MockServerModel, 10, {name: Fabricator.uniqueId('album_'), created_at: Fabricator.date, updated_at: Fabricator.date}, callback)
    queue.await (err) -> callback(null, _.map(_.toArray(arguments).pop(), (test) -> JSONUtils.valueToJSON(test.toJSON())))

require('../../lib/test_generators/server_model')(test_parameters)
