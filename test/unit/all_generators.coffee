_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

JSONUtils = require '../../lib/json_utils'
class FirstMemoryModel extends Backbone.Model
  sync: require('../../memory_backbone_sync')(FirstMemoryModel)
class SecondMemoryModel extends Backbone.Model
  @schema:
    first: -> ['hasOne', FirstMemoryModel, reverse: true]
  sync: require('../../memory_backbone_sync')(SecondMemoryModel)
class ThirdMemoryModel extends Backbone.Model
  @schema:
    firsts: -> ['hasMany', FirstMemoryModel]
    second: -> ['hasOne', SecondMemoryModel]
  sync: require('../../memory_backbone_sync')(FirstMemoryModel)
Fabricator = require '../../fabricator'

FirstMemoryModel.initialize()
SecondMemoryModel.initialize()

test_parameters =
  model_type: FirstMemoryModel
  route: 'mock_models'
  beforeEach: (callback) ->
    queue = new Queue(1)
    queue.defer (callback) -> FirstMemoryModel.destroy {}, callback
    queue.defer (callback) -> Fabricator.create(FirstMemoryModel, 10, {
      name: Fabricator.uniqueId('album_')
      created_at: Fabricator.date
      updated_at: Fabricator.date
    }, callback)
    queue.await (err) -> callback(null, _.map(_.toArray(arguments).pop(), (test) -> JSONUtils.valueToJSON(test.toJSON())))

require('../../lib/test_generators/all')(test_parameters)
