_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

JSONUtils = require '../../lib/json_utils'
class MemoryModel extends Backbone.Model
  sync: require('../../memory_backbone_sync')(MemoryModel)
Fabricator = require '../../fabricator'

test_parameters =
  model_type: MemoryModel
  route: 'mock_models'
  beforeEach: (callback) ->
    queue = new Queue(1)
    queue.defer (callback) -> MemoryModel.destroy {}, callback
    queue.defer (callback) -> Fabricator.create(MemoryModel, 10, {
      name: Fabricator.uniqueId('album_')
      created_at: Fabricator.date
      updated_at: Fabricator.date
    }, callback)
    queue.await (err) -> callback(null, _.map(_.toArray(arguments).pop(), (test) -> JSONUtils.valueToJSON(test.toJSON())))

require('../../lib/test_generators/all')(test_parameters)
