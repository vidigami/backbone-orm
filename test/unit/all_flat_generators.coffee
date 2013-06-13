_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

JSONUtils = require '../../lib/json_utils'

class FlatMemoryModel extends Backbone.Model
  sync: require('../../memory_backbone_sync')(FlatMemoryModel)

test_parameters =
  model_type: FlatMemoryModel
  route: 'mock_models'
  beforeEach: (callback) ->
    queue = new Queue(1)
    queue.defer (callback) -> FlatMemoryModel.destroy {}, callback
    queue.defer (callback) -> Fabricator.create(FlatMemoryModel, 10, {
      name: Fabricator.uniqueId('album_')
      created_at: Fabricator.date
      updated_at: Fabricator.date
    }, callback)
    queue.await (err) -> callback(null, _.map(_.toArray(arguments).pop(), (test) -> JSONUtils.valueToJSON(test.toJSON())))

require('../../lib/test_generators/all_flat')(test_parameters)
