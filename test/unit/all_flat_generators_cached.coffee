_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

Fabricator = require '../../fabricator'

class FlatModel extends Backbone.Model
  url: '/flat_models'
  sync: require('../../memory_backbone_sync')(FlatModel, true)

test_parameters =
  model_type: FlatModel
  route: 'mock_models'
  beforeEach: (callback) ->
    queue = new Queue(1)
    queue.defer (callback) -> FlatModel.destroy callback
    queue.defer (callback) -> Fabricator.create(FlatModel, 10, {
      name: Fabricator.uniqueId('album_')
      created_at: Fabricator.date
      updated_at: Fabricator.date
    }, callback)
    queue.await (err) -> callback(null, _.map(_.toArray(arguments).pop(), (test) -> test.toJSON()))

require('../../lib/test_generators/all_flat')(test_parameters)
